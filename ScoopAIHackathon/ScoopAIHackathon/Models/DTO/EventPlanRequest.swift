//
//  EventPlanRequest.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - Event Plan Request
struct EventPlanRequest: Codable {
    let eventName: String           // 행사명
    let startDate: Date             // 행사 시작일
    let endDate: Date               // 행사 종료일
    let targetAudience: String      // 행사대상
    let eventLocation: String       // 행사장소
    let staffCount: Int             // 스태프 인원
    let participantCount: Int       // 참가 인원
    let budget: Int?                // 소요예산 (선택)
    let requiredEquipment: String?  // 필요비품 (선택)
    let eventOverview: String       // 행사개요
    let eventContent: String        // 행사내용

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case eventName = "event_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case targetAudience = "target_audience"
        case eventLocation = "event_location"
        case staffCount = "staff_count"
        case participantCount = "participant_count"
        case budget
        case requiredEquipment = "required_equipment"
        case eventOverview = "event_overview"
        case eventContent = "event_content"
    }

    // MARK: - Prompt Generation
    /// AI 프롬프트 생성
    func generatePrompt() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDateStr = dateFormatter.string(from: startDate)
        let endDateStr = dateFormatter.string(from: endDate)
        let budgetStr = budget.map { "\($0)원" } ?? "미정"
        let equipmentStr = requiredEquipment ?? "없음"

        return """
        당신은 10년 경력의 전문 행사 기획자입니다.
        사용자가 입력한 행사 정보를 분석하여 체계적인 일정 계획을 수립해주세요.

        ## 입력 정보

        - 행사명: \(eventName)
        - 행사기간: \(startDateStr) ~ \(endDateStr)
        - 행사대상: \(targetAudience)
        - 행사장소: \(eventLocation)
        - 스태프 인원: \(staffCount)명
        - 참가 인원: \(participantCount)명
        - 소요예산: \(budgetStr)
        - 필요비품: \(equipmentStr)
        - 행사개요: \(eventOverview)
        - 행사내용: \(eventContent)

        ## 작업 지침

        1. 행사 시작일 기준 최소 2주 전부터 행사 종료 후 정리까지의 전체 일정을 계획하세요.
        2. 모든 일정과 체크리스트는 담당 카테고리별로 분류하세요.
        3. 스태프 인원과 참가 인원 규모에 맞는 현실적인 계획을 세우세요.
        4. 예산이 입력된 경우 예산 범위 내에서 실행 가능한 계획을 제시하세요.

        ## 담당 카테고리

        - planning: 기획 (전체 총괄, 일정 조율, 프로그램 구성, 섭외)
        - finance: 재무 (예산 관리, 견적, 계약, 정산)
        - facilities: 설비 (장소, 장비, 물품, 설치/철거)
        - promotion: 홍보 (SNS, 포스터, 안내, 참가자 커뮤니케이션)
        - operations: 운영 (당일 진행, 인력 배치, 동선, 안전)

        ## 출력 형식 (반드시 아래 JSON 구조를 따르세요)

        {
          "eventSummary": {
            "name": "행사명",
            "period": "YYYY-MM-DD ~ YYYY-MM-DD",
            "totalDays": 0,
            "prepDays": 0
          },

          "schedules": [
            {
              "id": "sch_001",
              "date": "YYYY-MM-DD",
              "startTime": "HH:MM",
              "endTime": "HH:MM",
              "title": "일정 제목",
              "description": "상세 설명",
              "phase": "prep | main | cleanup",
              "category": "planning | finance | facilities | promotion | operations",
              "location": "장소"
            }
          ],

          "dailyChecklists": [
            {
              "date": "YYYY-MM-DD",
              "dDay": "D-14",
              "tasksByCategory": {
                "planning": [
                  {
                    "id": "task_001",
                    "task": "구체적인 할 일",
                    "priority": "high | medium | low",
                    "estimatedTime": "소요 예상 시간"
                  }
                ],
                "finance": [],
                "facilities": [],
                "promotion": [],
                "operations": []
              }
            }
          ]
        }

        ## phase 설명
        - prep: 사전 준비 (D-14 ~ D-1)
        - main: 본행사 (D-Day)
        - cleanup: 정리 및 마무리 (D+1~)

        ## 주의사항

        1. 모든 날짜는 ISO 형식(YYYY-MM-DD)으로 작성하세요.
        2. 시간은 24시간 형식(HH:MM)으로 작성하세요.
        3. 체크리스트는 실행 가능한 단위로 세분화하세요. (예: "홍보하기" X → "인스타그램 행사 안내 게시물 작성" O)
        4. 행사 규모(인원)에 비례하여 준비 기간과 체크리스트 양을 조절하세요.
        5. 해당 날짜에 할 일이 없는 카테고리는 빈 배열로 두세요.
        6. JSON만 출력하세요. 다른 텍스트는 포함하지 마세요.
        """
    }
}
