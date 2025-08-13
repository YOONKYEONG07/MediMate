// ChatCategory.swift (새 파일 or 기존 파일 상단에 추가)
enum ChatCategory: String {
    case interaction = "약물 간 상호작용"
    case usageTiming = "복용 방법 및 시기"
    case precaution = "금기 사항/부작용"
    case supplement = "영양제 추천"
    case general = "상담 / 기타 문의"

    static func fromButtonTitle(_ title: String) -> ChatCategory {
        switch title {
        case "💊 약물 간 상호작용": return .interaction
        case "⏰ 복용 방법 및 시기": return .usageTiming
        case "⚠️ 금기 사항/부작용": return .precaution
        case "💪 영양제 추천": return .supplement
        case "💬 상담 / 기타 문의": return .general
        default: return .general
        }
    }

    /// 카테고리별 가드레일(모델 규칙)
    var guardrail: String {
        switch self {
        case .interaction:
            return "카테고리=약물 간 상호작용. 상호작용만 다뤄라. 모르면 모른다고 말해라. 복용법/추천으로 새지 마라."
        case .usageTiming:
            return "카테고리=복용 방법 및 시기. 식전/식후/시간/용량 일반 가이드만. 상호작용/추천으로 새지 마라."
        case .precaution:
            return "카테고리=금기 사항/부작용. 금기/주의/흔한·심각 부작용 중심. 다른 주제로 새지 마라."
        case .supplement:
            return "카테고리=영양제 추천. 성분 1~3개 제안+짧은 근거. 치료 단정 금지. 주의는 간단히."
        case .general:
            return "카테고리=상담/기타 문의. 일반 상담 톤으로 간결하게."
        }
    }
}

