//
//  QTISerializer.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//  Updated 2025-11-19 for Canvas compatibility and concurrency
//

import Foundation

/// Serializes QTIDocumentSnapshot models into Canvas-compatible QTI 1.2 XML
final class QTISerializer {
    /// Serializes a QTIDocumentSnapshot to QTI XML data
    /// - Parameter snapshot: The document snapshot to serialize
    /// - Returns: XML data
    /// - Throws: QTIError if serialization fails
    func serialize(snapshot: QTIDocumentSnapshot) throws -> Data {
        let xmlDoc = try generateXML(for: snapshot)
        return xmlDoc.xmlData(options: [.nodePrettyPrint])
     }

    /// Serializes a QTIDocumentSnapshot to a file
    /// - Parameters:
    ///   - snapshot: The document snapshot to serialize
    ///   - url: Destination file URL
    /// - Throws: QTIError if serialization fails
    func serialize(snapshot: QTIDocumentSnapshot, to url: URL) throws {
        let data = try serialize(snapshot: snapshot)

        do {
            try data.write(to: url)
        } catch {
            throw QTIError.cannotWriteFile(url.path)
        }
    }

    // MARK: - XML Generation

    private func generateXML(for snapshot: QTIDocumentSnapshot) throws -> XMLDocument {
        // Create root element with proper Canvas namespaces
        let root = XMLElement(name: "questestinterop")
        let ns = XMLNode.namespace(withName: "", stringValue: "http://www.imsglobal.org/xsd/ims_qtiasiv1p2") as! XMLNode
        let xsiNS = XMLNode.namespace(withName: "xsi", stringValue: "http://www.w3.org/2001/XMLSchema-instance") as! XMLNode
        root.addNamespace(ns)
        root.addNamespace(xsiNS)

        // Add schema location
        let schemaLocation = XMLNode.attribute(
            withName: "xsi:schemaLocation",
            stringValue: "http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd"
        ) as! XMLNode
        root.addAttribute(schemaLocation)

        // Create assessment element
        let assessment = createAssessmentElement(for: snapshot)
        root.addChild(assessment)

        // Create XML document
        let xmlDoc = XMLDocument(rootElement: root)
        xmlDoc.version = "1.0"

        return xmlDoc
    }

    private func createAssessmentElement(for snapshot: QTIDocumentSnapshot) -> XMLElement {
        let assessment = XMLElement(name: "assessment")

        // Set attributes
        let identifier = snapshot.metadata["canvas_identifier"] ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        assessment.addAttribute(XMLNode.attribute(withName: "ident", stringValue: identifier) as! XMLNode)
        assessment.addAttribute(XMLNode.attribute(withName: "title", stringValue: snapshot.title) as! XMLNode)

        // Add external_assignment_id if available
        if let assignmentID = snapshot.metadata["external_assignment_id"] {
            assessment.addAttribute(XMLNode.attribute(withName: "external_assignment_id", stringValue: assignmentID) as! XMLNode)
        }

        // Add assessment-level qtimetadata
        let qtimetadata = createAssessmentMetadata(for: snapshot)
        assessment.addChild(qtimetadata)

        // Create section containing all questions
        let section = createSectionElement(for: snapshot.questions)
        assessment.addChild(section)

        return assessment
    }

    private func createAssessmentMetadata(for snapshot: QTIDocumentSnapshot) -> XMLElement {
        let qtimetadata = XMLElement(name: "qtimetadata")

        // Add cc_maxattempts
        let maxAttemptsField = XMLElement(name: "qtimetadatafield")
        maxAttemptsField.addChild(XMLElement(name: "fieldlabel", stringValue: "cc_maxattempts"))
        maxAttemptsField.addChild(XMLElement(name: "fieldentry", stringValue: snapshot.metadata["cc_maxattempts"] ?? "1"))
        qtimetadata.addChild(maxAttemptsField)

        return qtimetadata
    }

    private func createSectionElement(for questions: [QTIQuestion]) -> XMLElement {
        let section = XMLElement(name: "section")
        section.addAttribute(XMLNode.attribute(withName: "ident", stringValue: "root_section") as! XMLNode)

        // Add all questions as items
        for question in questions {
            let item = createItemElement(for: question)
            section.addChild(item)
        }

        return section
    }

    // MARK: - Item (Question) Generation

    private func createItemElement(for question: QTIQuestion) -> XMLElement {
        let item = XMLElement(name: "item")

        let identifier = question.metadata["canvas_identifier"] ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let title = question.metadata["canvas_title"] ?? "Question"

        item.addAttribute(XMLNode.attribute(withName: "ident", stringValue: identifier) as! XMLNode)
        item.addAttribute(XMLNode.attribute(withName: "title", stringValue: title) as! XMLNode)

        // Add itemmetadata with comprehensive Canvas fields
        let itemmetadata = createItemMetadata(for: question)
        item.addChild(itemmetadata)

        // Add presentation
        let presentation = createPresentationElement(for: question)
        item.addChild(presentation)

        // Add resprocessing
        let resprocessing = createResponseProcessingElement(for: question)
        item.addChild(resprocessing)

        return item
    }

    // MARK: - Helper Methods

    /// Ensures an answer has a canvas_identifier, generating one if needed
    private func ensureCanvasIdentifier(for answer: QTIAnswer) -> String {
        if let existing = answer.metadata["canvas_identifier"] {
            return existing
        }
        // Fallback (should be handled by model init usually)
        return UUID().uuidString.lowercased()
    }

    private func createItemMetadata(for question: QTIQuestion) -> XMLElement {
        let itemmetadata = XMLElement(name: "itemmetadata")
        let qtimetadata = XMLElement(name: "qtimetadata")

        // Question type
        addMetadataField(to: qtimetadata, label: "question_type", entry: question.type.rawValue)

        // Points possible
        addMetadataField(to: qtimetadata, label: "points_possible", entry: String(format: "%.1f", question.points))

        // Original answer IDs (comma-separated UUIDs)
        let answerIDs = question.answers.map { answer in
            ensureCanvasIdentifier(for: answer)
        }.joined(separator: ",")
        addMetadataField(to: qtimetadata, label: "original_answer_ids", entry: answerIDs)

        // Assessment question identifier ref (if available)
        if let assessmentQuestionRef = question.metadata["assessment_question_identifierref"] {
            addMetadataField(to: qtimetadata, label: "assessment_question_identifierref", entry: assessmentQuestionRef)
        }

        // Calculator type
        addMetadataField(to: qtimetadata, label: "calculator_type", entry: question.metadata["calculator_type"] ?? "none")

        itemmetadata.addChild(qtimetadata)
        return itemmetadata
    }

    private func addMetadataField(to qtimetadata: XMLElement, label: String, entry: String) {
        let field = XMLElement(name: "qtimetadatafield")
        field.addChild(XMLElement(name: "fieldlabel", stringValue: label))
        field.addChild(XMLElement(name: "fieldentry", stringValue: entry))
        qtimetadata.addChild(field)
    }

    // MARK: - Presentation Generation

    private func createPresentationElement(for question: QTIQuestion) -> XMLElement {
        let presentation = XMLElement(name: "presentation")

        // Add question text material (with HTML encoding)
        let material = createMaterialElement(with: question.questionText)
        presentation.addChild(material)

        // Add response based on question type
        switch question.type {
        case .multipleChoice, .trueFalse, .multipleAnswers:
            let responseLid = createResponseLidElement(for: question)
            presentation.addChild(responseLid)

        case .essay:
            let responseStr = createResponseStrElement(for: question)
            presentation.addChild(responseStr)

        default:
            // For other types, add a basic response_lid
            let responseLid = createResponseLidElement(for: question)
            presentation.addChild(responseLid)
        }

        return presentation
    }

    private func createMaterialElement(with htmlContent: String) -> XMLElement {
        let material = XMLElement(name: "material")
        let mattext = XMLElement(name: "mattext", stringValue: htmlContent)
        mattext.addAttribute(XMLNode.attribute(withName: "texttype", stringValue: "text/html") as! XMLNode)

        material.addChild(mattext)
        return material
    }

    private func createResponseLidElement(for question: QTIQuestion) -> XMLElement {
        let responseLid = XMLElement(name: "response_lid")
        responseLid.addAttribute(XMLNode.attribute(withName: "ident", stringValue: "response1") as! XMLNode)
        responseLid.addAttribute(XMLNode.attribute(withName: "rcardinality", stringValue: "Single") as! XMLNode)

        let renderChoice = XMLElement(name: "render_choice")

        // Add response labels for each answer with UUIDs
        for answer in question.answers {
            let responseLabel = XMLElement(name: "response_label")
            let identifier = ensureCanvasIdentifier(for: answer)
            responseLabel.addAttribute(XMLNode.attribute(withName: "ident", stringValue: identifier) as! XMLNode)

            let material = createMaterialElement(with: answer.text)
            responseLabel.addChild(material)
            renderChoice.addChild(responseLabel)
        }

        responseLid.addChild(renderChoice)
        return responseLid
    }

    private func createResponseStrElement(for question: QTIQuestion) -> XMLElement {
        let responseStr = XMLElement(name: "response_str")
        responseStr.addAttribute(XMLNode.attribute(withName: "ident", stringValue: "response1") as! XMLNode)
        responseStr.addAttribute(XMLNode.attribute(withName: "rcardinality", stringValue: "Single") as! XMLNode)

        let renderFib = XMLElement(name: "render_fib")
        renderFib.addAttribute(XMLNode.attribute(withName: "fibtype", stringValue: "String") as! XMLNode)

        responseStr.addChild(renderFib)
        return responseStr
    }

    // MARK: - Response Processing Generation

    private func createResponseProcessingElement(for question: QTIQuestion) -> XMLElement {
        let resprocessing = XMLElement(name: "resprocessing")

        // Add outcomes declaration
        let outcomes = XMLElement(name: "outcomes")
        let decvar = XMLElement(name: "decvar")
        decvar.addAttribute(XMLNode.attribute(withName: "maxvalue", stringValue: "100") as! XMLNode)
        decvar.addAttribute(XMLNode.attribute(withName: "minvalue", stringValue: "0") as! XMLNode)
        decvar.addAttribute(XMLNode.attribute(withName: "varname", stringValue: "SCORE") as! XMLNode)
        decvar.addAttribute(XMLNode.attribute(withName: "vartype", stringValue: "Decimal") as! XMLNode)
        outcomes.addChild(decvar)
        resprocessing.addChild(outcomes)

        // Add correct answer conditions
        for answer in question.answers where answer.isCorrect {
            let identifier = ensureCanvasIdentifier(for: answer)
            let respcondition = createResponseCondition(
                identifier: identifier,
                score: 100 // Canvas expects 100 for correct answers
            )
            resprocessing.addChild(respcondition)
        }

        return resprocessing
    }

    private func createResponseCondition(identifier: String, score: Int) -> XMLElement {
        let respcondition = XMLElement(name: "respcondition")
        respcondition.addAttribute(XMLNode.attribute(withName: "continue", stringValue: "No") as! XMLNode)

        // Condition variable
        let conditionvar = XMLElement(name: "conditionvar")
        let varequal = XMLElement(name: "varequal", stringValue: identifier)
        varequal.addAttribute(XMLNode.attribute(withName: "respident", stringValue: "response1") as! XMLNode)
        conditionvar.addChild(varequal)
        respcondition.addChild(conditionvar)

        // Set score
        let setvar = XMLElement(name: "setvar", stringValue: String(score))
        setvar.addAttribute(XMLNode.attribute(withName: "action", stringValue: "Set") as! XMLNode)
        setvar.addAttribute(XMLNode.attribute(withName: "varname", stringValue: "SCORE") as! XMLNode)
        respcondition.addChild(setvar)

        return respcondition
    }
}
