//
//  IMSCCPackageGenerator.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import Foundation

/// Service for generating IMSCC package components (manifest, metadata)
enum IMSCCPackageGenerator {

    /// Generates the imsmanifest.xml file
    static func generateManifest(for snapshot: QTIDocument, quizID: String, to url: URL) throws {
        // Generate a unique manifest ID
        let manifestID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let metaResourceID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD

        let xml = """
        <?xml version="1.0"?>
        <manifest xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1" xmlns:lom="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource" xmlns:imsmd="http://www.imsglobal.org/xsd/imsmd_v1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" identifier="\(manifestID)" xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://www.imsglobal.org/xsd/imsmd_v1p2 http://www.imsglobal.org/xsd/imsmd_v1p2p2.xsd">
          <metadata>
            <schema>IMS Content</schema>
            <schemaversion>1.1.3</schemaversion>
            <imsmd:lom>
              <imsmd:general>
                <imsmd:title>
                  <imsmd:string>QTI Quiz Export for \(xmlEscape(snapshot.title))</imsmd:string>
                </imsmd:title>
              </imsmd:general>
              <imsmd:lifeCycle>
                <imsmd:contribute>
                  <imsmd:date>
                    <imsmd:dateTime>\(today)</imsmd:dateTime>
                  </imsmd:date>
                </imsmd:contribute>
              </imsmd:lifeCycle>
              <imsmd:rights>
                <imsmd:copyrightAndOtherRestrictions>
                  <imsmd:value>yes</imsmd:value>
                </imsmd:copyrightAndOtherRestrictions>
                <imsmd:description>
                  <imsmd:string>Private (Copyrighted) - http://en.wikipedia.org/wiki/Copyright</imsmd:string>
                </imsmd:description>
              </imsmd:rights>
            </imsmd:lom>
          </metadata>
          <organizations/>
          <resources>
            <resource identifier="\(quizID)" type="imsqti_xmlv1p2">
              <file href="\(quizID)/\(quizID).xml"/>
              <dependency identifierref="\(metaResourceID)"/>
            </resource>
            <resource identifier="\(metaResourceID)" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="\(quizID)/assessment_meta.xml">
              <file href="\(quizID)/assessment_meta.xml"/>
            </resource>
          </resources>
        </manifest>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Generates the assessment_meta.xml file
    static func generateAssessmentMeta(for snapshot: QTIDocument, quizID: String, to url: URL) throws {
        let assignmentID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let assignmentGroupID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let pointsPossible = snapshot.questions.reduce(0.0) { $0 + $1.points }

        let xml = """
        <?xml version="1.0"?>
        <quiz xmlns="http://canvas.instructure.com/xsd/cccv1p0" xmlns:xsi="http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd" identifier="\(quizID)">
          <title>\(xmlEscape(snapshot.title))</title>
          <description>\(xmlEscape(snapshot.description))</description>
          <due_at/>
          <lock_at/>
          <unlock_at/>
          <shuffle_questions>false</shuffle_questions>
          <shuffle_answers>false</shuffle_answers>
          <calculator_type>none</calculator_type>
          <scoring_policy>keep_highest</scoring_policy>
          <hide_results/>
          <quiz_type>assignment</quiz_type>
          <points_possible>\(pointsPossible)</points_possible>
          <require_lockdown_browser>false</require_lockdown_browser>
          <require_lockdown_browser_for_results>false</require_lockdown_browser_for_results>
          <require_lockdown_browser_monitor>false</require_lockdown_browser_monitor>
          <lockdown_browser_monitor_data/>
          <show_correct_answers>false</show_correct_answers>
          <anonymous_submissions>false</anonymous_submissions>
          <could_be_locked>false</could_be_locked>
          <disable_timer_autosubmission>false</disable_timer_autosubmission>
          <allowed_attempts>1</allowed_attempts>
          <build_on_last_attempt>false</build_on_last_attempt>
          <one_question_at_a_time>false</one_question_at_a_time>
          <cant_go_back>false</cant_go_back>
          <available>false</available>
          <one_time_results>false</one_time_results>
          <show_correct_answers_last_attempt>false</show_correct_answers_last_attempt>
          <only_visible_to_overrides>false</only_visible_to_overrides>
          <module_locked>false</module_locked>
          <allow_clear_mc_selection/>
          <disable_document_access>false</disable_document_access>
          <result_view_restricted>false</result_view_restricted>
          <assignment identifier="\(assignmentID)">
            <title>\(xmlEscape(snapshot.title))</title>
            <due_at/>
            <lock_at/>
            <unlock_at/>
            <module_locked>false</module_locked>
            <workflow_state>unpublished</workflow_state>
            <assignment_overrides/>
            <assignment_overrides/>
            <quiz_identifierref>\(quizID)</quiz_identifierref>
            <allowed_extensions/>
            <has_group_category>false</has_group_category>
            <points_possible>\(pointsPossible)</points_possible>
            <grading_type>points</grading_type>
            <all_day>false</all_day>
            <submission_types>online_quiz</submission_types>
            <position>1</position>
            <turnitin_enabled>false</turnitin_enabled>
            <vericite_enabled>false</vericite_enabled>
            <peer_review_count>0</peer_review_count>
            <peer_reviews>false</peer_reviews>
            <automatic_peer_reviews>false</automatic_peer_reviews>
            <anonymous_peer_reviews>false</anonymous_peer_reviews>
            <grade_group_students_individually>false</grade_group_students_individually>
            <freeze_on_copy>false</freeze_on_copy>
            <omit_from_final_grade>false</omit_from_final_grade>
            <intra_group_peer_reviews>false</intra_group_peer_reviews>
            <only_visible_to_overrides>false</only_visible_to_overrides>
            <post_to_sis>false</post_to_sis>
            <moderated_grading>false</moderated_grading>
            <grader_count>0</grader_count>
            <grader_comments_visible_to_graders>true</grader_comments_visible_to_graders>
            <anonymous_grading>false</anonymous_grading>
            <graders_anonymous_to_graders>false</graders_anonymous_to_graders>
            <grader_names_visible_to_final_grader>true</grader_names_visible_to_final_grader>
            <anonymous_instructor_annotations>false</anonymous_instructor_annotations>
            <post_policy>
              <post_manually>false</post_manually>
            </post_policy>
            <assignment_group_identifierref>\(assignmentGroupID)</assignment_group_identifierref>
            <assignment_overrides/>
          </assignment>
        </quiz>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
