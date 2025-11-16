//
//  QTISerializer.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Serializes QTIDocument models into QTI 1.2 XML
@MainActor
final class QTISerializer {
    /// Serializes a QTIDocument to QTI XML data
    /// - Parameter document: The document to serialize
    /// - Returns: XML data
    /// - Throws: QTIError if serialization fails
    func serialize(document: QTIDocument) throws -> Data {
        let xmlDoc = try generateXML(for: document)

        guard let data = xmlDoc.xmlData(options: [.nodePrettyPrint]) else {
            throw QTIError.serializationFailed("Could not generate XML data")
        }

        return data
    }

    /// Serializes a QTIDocument to a file
    /// - Parameters:
    ///   - document: The document to serialize
    ///   - url: Destination file URL
    /// - Throws: QTIError if serialization fails
    func serialize(document: QTIDocument, to url: URL) throws {
        let data = try serialize(document: document)

        do {
            try data.write(to: url)
        } catch {
            throw QTIError.cannotWriteFile(url.path)
        }
    }

    // MARK: - XML Generation

    private func generateXML(for document: QTIDocument) throws -> XMLDocument {
        // Create root element
        let root = XMLElement(name: "questestinterop")

        // Create assessment element
        let assessment = createAssessmentElement(for: document)
        root.addChild(assessment)

        // Create XML document
        let xmlDoc = XMLDocument(rootElement: root)
        xmlDoc.version = "1.0"
        xmlDoc.characterEncoding = "UTF-8"

        return xmlDoc
    }

    private func createAssessmentElement(for document: QTIDocument) -> XMLElement {
        let assessment = XMLElement(name: "assessment")

        // Set attributes
        let identifier = document.metadata["canvas_identifier"] ?? UUID().uuidString
        assessment.addAttribute(XMLNode.attribute(withName: "ident", stringValue: identifier) as! XMLNode)
        assessment.addAttribute(XMLNode.attribute(withName: "title", stringValue: document.title) as! XMLNode)

        // Create section containing all questions
        let section = createSectionElement(for: document.questions)
        assessment.addChild(section)

        return assessment
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

        let identifier = question.metadata["canvas_identifier"] ?? UUID().uuidString
        let title = question.metadata["canvas_title"] ?? "Question"

        item.addAttribute(XMLNode.attribute(withName: "ident", stringValue: identifier) as! XMLNode)
        item.addAttribute(XMLNode.attribute(withName: "title", stringValue: title) as! XMLNode)

        // Add itemmetadata with question type
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

    private func createItemMetadata(for question: QTIQuestion) -> XMLElement {
        let itemmetadata = XMLElement(name: "itemmetadata")
        let qtimetadata = XMLElement(name: "qtimetadata")

        // Add question_type field
        let metadatafield = XMLElement(name: "qtimetadatafield")

        let fieldlabel = XMLElement(name: "fieldlabel", stringValue: "question_type")
        let fieldentry = XMLElement(name: "fieldentry", stringValue: question.type.rawValue)

        metadatafield.addChild(fieldlabel)
        metadatafield.addChild(fieldentry)
        qtimetadata.addChild(metadatafield)
        itemmetadata.addChild(qtimetadata)

        return itemmetadata
    }

    // MARK: - Presentation Generation

    private func createPresentationElement(for question: QTIQuestion) -> XMLElement {
        let presentation = XMLElement(name: "presentation")

        // Add question text material
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

        // Add response labels for each answer
        for (index, answer) in question.answers.enumerated() {
            let responseLabel = XMLElement(name: "response_label")
            let identifier = "answer_\(index)"
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
        for (index, answer) in question.answers.enumerated() where answer.isCorrect {
            let respcondition = createResponseCondition(
                for: answer,
                identifier: "answer_\(index)",
                points: question.points
            )
            resprocessing.addChild(respcondition)
        }

        return resprocessing
    }

    private func createResponseCondition(
        for answer: QTIAnswer,
        identifier: String,
        points: Double
    ) -> XMLElement {
        let respcondition = XMLElement(name: "respcondition")
        respcondition.addAttribute(XMLNode.attribute(withName: "continue", stringValue: "No") as! XMLNode)

        // Condition variable
        let conditionvar = XMLElement(name: "conditionvar")
        let varequal = XMLElement(name: "varequal", stringValue: identifier)
        varequal.addAttribute(XMLNode.attribute(withName: "respident", stringValue: "response1") as! XMLNode)
        conditionvar.addChild(varequal)
        respcondition.addChild(conditionvar)

        // Set score
        let setvar = XMLElement(name: "setvar", stringValue: String(format: "%.2f", points))
        setvar.addAttribute(XMLNode.attribute(withName: "action", stringValue: "Set") as! XMLNode)
        setvar.addAttribute(XMLNode.attribute(withName: "varname", stringValue: "SCORE") as! XMLNode)
        respcondition.addChild(setvar)

        return respcondition
    }
}
