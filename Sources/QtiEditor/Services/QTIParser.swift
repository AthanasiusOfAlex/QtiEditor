//
//  QTIParser.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Parses QTI 1.2 XML documents into QTIDocument models
@MainActor
final class QTIParser {
    /// Parses a QTI XML file into a QTIDocument
    /// - Parameter url: URL to the assessment.xml file
    /// - Returns: Parsed QTIDocument
    /// - Throws: QTIError if parsing fails
    func parse(fileURL url: URL) async throws -> QTIDocument {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    /// Parses QTI XML data into a QTIDocument
    /// - Parameter data: XML data
    /// - Returns: Parsed QTIDocument
    /// - Throws: QTIError if parsing fails
    func parse(data: Data) throws -> QTIDocument {
        let xmlDoc: XMLDocument
        do {
            xmlDoc = try XMLDocument(data: data)
        } catch {
            throw QTIError.xmlParseError(error.localizedDescription)
        }

        // Verify root element is questestinterop
        guard let root = xmlDoc.rootElement(),
              root.name == "questestinterop" else {
            throw QTIError.invalidQTIStructure("Root element must be <questestinterop>")
        }

        // Find assessment element
        guard let assessmentElement = root.elements(forName: "assessment").first else {
            throw QTIError.missingRequiredElement("assessment")
        }

        return try parseAssessment(assessmentElement)
    }

    // MARK: - Assessment Parsing

    private func parseAssessment(_ element: XMLElement) throws -> QTIDocument {
        // Parse assessment attributes
        let title = element.attribute(forName: "title")?.stringValue ?? "Untitled Quiz"
        let identifier = element.attribute(forName: "ident")?.stringValue ?? UUID().uuidString
        let externalAssignmentID = element.attribute(forName: "external_assignment_id")?.stringValue

        // Parse assessment-level metadata
        var assessmentMetadata: [String: String] = [
            "canvas_identifier": identifier
        ]

        if let externalAssignmentID = externalAssignmentID {
            assessmentMetadata["external_assignment_id"] = externalAssignmentID
        }

        // Parse qtimetadata for cc_maxattempts, etc.
        if let qtimetadata = element.elements(forName: "qtimetadata").first {
            for metadatafield in qtimetadata.elements(forName: "qtimetadatafield") {
                if let fieldlabel = metadatafield.elements(forName: "fieldlabel").first,
                   let fieldentry = metadatafield.elements(forName: "fieldentry").first,
                   let label = fieldlabel.stringValue,
                   let entry = fieldentry.stringValue {
                    assessmentMetadata[label] = entry
                }
            }
        }

        // Parse sections (questions are typically in sections)
        let sections = element.elements(forName: "section")
        var allQuestions: [QTIQuestion] = []

        for section in sections {
            let questions = try parseSection(section)
            allQuestions.append(contentsOf: questions)
        }

        // Create document
        let document = QTIDocument(
            id: UUID(), // Generate new UUID (Canvas ID stored in metadata)
            title: title,
            description: "",
            questions: allQuestions,
            metadata: assessmentMetadata
        )

        return document
    }

    // MARK: - Section Parsing

    private func parseSection(_ element: XMLElement) throws -> [QTIQuestion] {
        let items = element.elements(forName: "item")
        var questions: [QTIQuestion] = []

        for item in items {
            if let question = try? parseItem(item) {
                questions.append(question)
            }
        }

        return questions
    }

    // MARK: - Item (Question) Parsing

    private func parseItem(_ element: XMLElement) throws -> QTIQuestion {
        let identifier = element.attribute(forName: "ident")?.stringValue ?? UUID().uuidString
        let title = element.attribute(forName: "title")?.stringValue ?? ""

        // Parse presentation (question text and answers)
        guard let presentation = element.elements(forName: "presentation").first else {
            throw QTIError.missingRequiredElement("presentation in item")
        }

        let (questionText, questionType) = try parsePresentation(presentation)

        // Parse response processing (correct answers and points)
        let (answers, points) = try parseResponseProcessing(
            element.elements(forName: "resprocessing").first,
            presentation: presentation,
            questionType: questionType
        )

        // Parse metadata for question type and other Canvas fields
        let actualType = parseQuestionType(from: element) ?? questionType
        let questionMetadata = parseQuestionMetadata(from: element, identifier: identifier, title: title)

        let question = QTIQuestion(
            id: UUID(),
            type: actualType,
            questionText: questionText,
            points: points,
            answers: answers,
            generalFeedback: "",
            metadata: questionMetadata
        )

        return question
    }

    private func parseQuestionMetadata(from itemElement: XMLElement, identifier: String, title: String) -> [String: String] {
        var metadata: [String: String] = [
            "canvas_identifier": identifier,
            "canvas_title": title
        ]

        // Parse itemmetadata fields
        if let itemmetadata = itemElement.elements(forName: "itemmetadata").first {
            for qtimetadata in itemmetadata.elements(forName: "qtimetadata") {
                for metadatafield in qtimetadata.elements(forName: "qtimetadatafield") {
                    if let fieldlabel = metadatafield.elements(forName: "fieldlabel").first,
                       let fieldentry = metadatafield.elements(forName: "fieldentry").first,
                       let label = fieldlabel.stringValue,
                       let entry = fieldentry.stringValue {
                        metadata[label] = entry
                    }
                }
            }
        }

        return metadata
    }

    // MARK: - Presentation Parsing

    private func parsePresentation(_ element: XMLElement) throws -> (questionText: String, type: QTIQuestionType) {
        var questionText = ""
        var questionType: QTIQuestionType = .other

        // Find material (question text)
        if let material = element.elements(forName: "material").first {
            questionText = parseMaterial(material)
        }

        // Determine question type from response elements
        if element.elements(forName: "response_lid").first != nil {
            questionType = .multipleChoice
        } else if element.elements(forName: "response_str").first != nil {
            questionType = .essay
        }

        return (questionText, questionType)
    }

    private func parseMaterial(_ element: XMLElement) -> String {
        // Try to find mattext with HTML content
        if let mattext = element.elements(forName: "mattext").first {
            let texttype = mattext.attribute(forName: "texttype")?.stringValue
            if texttype == "text/html" {
                return mattext.stringValue ?? ""
            }
            // Plain text - wrap in paragraph
            if let text = mattext.stringValue, !text.isEmpty {
                return "<p>\(text)</p>"
            }
        }

        return "<p></p>"
    }

    // MARK: - Response Processing Parsing

    private func parseResponseProcessing(
        _ element: XMLElement?,
        presentation: XMLElement,
        questionType: QTIQuestionType
    ) throws -> (answers: [QTIAnswer], points: Double) {
        guard questionType == .multipleChoice else {
            return ([], 1.0)
        }

        // Parse answer choices from presentation
        guard let responseLid = presentation.elements(forName: "response_lid").first,
              let renderChoice = responseLid.elements(forName: "render_choice").first else {
            return ([], 1.0)
        }

        let responseLabels = renderChoice.elements(forName: "response_label")
        var answers: [QTIAnswer] = []
        var correctIdentifiers: Set<String> = []
        var points: Double = 1.0

        // Parse correct answers from resprocessing if available
        if let resprocessing = element {
            (correctIdentifiers, points) = parseCorrectAnswers(from: resprocessing)
        }

        // Build answer objects
        for label in responseLabels {
            let identifier = label.attribute(forName: "ident")?.stringValue ?? UUID().uuidString
            let isCorrect = correctIdentifiers.contains(identifier)

            var answerText = ""
            if let material = label.elements(forName: "material").first {
                answerText = parseMaterial(material)
            }

            // Store Canvas identifier in metadata for round-trip preservation
            let answer = QTIAnswer(
                id: UUID(),
                text: answerText,
                isCorrect: isCorrect,
                feedback: "",
                weight: isCorrect ? 100.0 : 0.0
            )
            answer.metadata["canvas_identifier"] = identifier

            answers.append(answer)
        }

        return (answers, points)
    }

    private func parseCorrectAnswers(from resprocessing: XMLElement) -> (identifiers: Set<String>, points: Double) {
        var correctIdentifiers: Set<String> = []
        var points: Double = 1.0

        // Find respcondition elements
        for respcondition in resprocessing.elements(forName: "respcondition") {
            // Check if this is a correct answer condition
            guard let conditionvar = respcondition.elements(forName: "conditionvar").first,
                  let setvar = respcondition.elements(forName: "setvar").first else {
                continue
            }

            // Check if setvar adds points (indicates correct answer)
            let action = setvar.attribute(forName: "action")?.stringValue
            let varValue = Double(setvar.stringValue ?? "0") ?? 0

            if action == "Set" && varValue > 0 {
                // This is a correct answer condition
                // Find the identifier in varequal
                if let varequal = conditionvar.elements(forName: "varequal").first,
                   let identifier = varequal.stringValue {
                    correctIdentifiers.insert(identifier)
                }

                // Update points if higher
                if varValue > points {
                    points = varValue
                }
            }
        }

        return (correctIdentifiers, points)
    }

    // MARK: - Question Type Detection

    private func parseQuestionType(from itemElement: XMLElement) -> QTIQuestionType? {
        // Check for Canvas-specific metadata
        if let itemmetadata = itemElement.elements(forName: "itemmetadata").first {
            for qtimetadata in itemmetadata.elements(forName: "qtimetadata") {
                for metadatafield in qtimetadata.elements(forName: "qtimetadatafield") {
                    if let fieldlabel = metadatafield.elements(forName: "fieldlabel").first,
                       let fieldentry = metadatafield.elements(forName: "fieldentry").first,
                       fieldlabel.stringValue == "question_type" {
                        let typeString = fieldentry.stringValue ?? ""
                        return QTIQuestionType(rawValue: typeString) ?? .other
                    }
                }
            }
        }

        return nil
    }
}
