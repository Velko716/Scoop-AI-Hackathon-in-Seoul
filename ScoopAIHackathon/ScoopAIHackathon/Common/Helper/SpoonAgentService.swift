//
//  SpoonAgentService.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

// MARK: - Preview Helper

#if DEBUG
extension SpoonAgentService {
    static var preview: SpoonAgentService {
        let service = SpoonAgentService()
        service.isReady = true
        return service
    }
}
#endif
