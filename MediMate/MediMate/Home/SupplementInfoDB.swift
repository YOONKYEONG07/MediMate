import Foundation

struct SupplementInfoDB {
    static let all: [String: SupplementInfo] = [
        "루테인": SupplementInfo(
            name: "루테인",
            function: "눈의 피로를 줄이고 황반을 보호해줍니다.",
            caution: "과다 복용 시 두통이나 메스꺼움을 유발할 수 있습니다.",
            method: "하루 1회, 식후에 섭취하세요."
        ),
        "비타민C": SupplementInfo(
            name: "비타민C",
            function: "항산화 작용 및 면역력 강화에 도움을 줍니다.",
            caution: "빈속에 복용 시 위에 자극을 줄 수 있습니다.",
            method: "하루 1~2회, 식후에 섭취하세요."
        ),
        "마그네슘": SupplementInfo(
            name: "마그네슘",
            function: "근육과 신경의 기능 유지에 도움을 줍니다.",
            caution: "설사 증상이 나타날 수 있으므로 권장량을 초과하지 마세요.",
            method: "하루 1회 섭취하세요."
        ),
        "밀크시슬": SupplementInfo(
                name: "밀크시슬",
                function: "간 기능을 보호하고 해독 작용을 도와줍니다.",
                caution: "특정 간 질환 약물과 상호작용할 수 있으니 주의하세요.",
                method: "하루 1회 식후에 섭취하세요."
        ),
        "오메가-3 지방산": SupplementInfo(
            name: "오메가-3 지방산",
            function: "혈중 중성지방 수치를 낮추고 심혈관 건강에 도움을 줍니다.",
            caution: "과다 복용 시 출혈 위험이 있을 수 있습니다.",
            method: "식사와 함께 하루 1~2회 섭취하세요."
        ),
        "콜라겐 보충제": SupplementInfo(
            name: "콜라겐 보충제",
            function: "피부 탄력과 관절 건강에 도움을 줍니다.",
            caution: "해산물 알레르기가 있다면 원재료를 확인하세요.",
            method: "공복에 하루 1~2회 섭취하세요."
        ),
        "비타민D": SupplementInfo(
            name: "비타민D",
            function: "뼈 건강과 면역력 증진에 도움을 줍니다.",
            caution: "지용성 비타민으로 과잉 섭취 시 체내 축적될 수 있습니다.",
            method: "식사 후 하루 1회 섭취하세요."
        ),
        "비오틴(비타민 B7)": SupplementInfo(
            name: "비오틴(비타민 B7)",
            function: "모발과 손톱 건강에 도움을 줍니다.",
            caution: "과다 섭취 시 여드름이 생길 수 있습니다.",
            method: "아침 식사 후 하루 1회 섭취하세요."
        ),
        "프로바이오틱스": SupplementInfo(
            name: "프로바이오틱스",
            function: "장 건강과 면역력 향상에 도움을 줍니다.",
            caution: "과민한 장을 가진 경우 복용량을 조절하세요.",
            method: "공복 또는 취침 전 하루 1회 섭취하세요."
        ),
        "철분과 엽산": SupplementInfo(
            name: "철분과 엽산",
            function: "빈혈 예방과 태아 신경관 형성에 도움을 줍니다.",
            caution: "철분은 위장 장애를 유발할 수 있으므로 식후 섭취하세요.",
            method: "하루 1회, 식사 후 충분한 물과 함께 복용하세요."
        ),
        "알파 리포산": SupplementInfo(
            name: "알파 리포산",
            function: "혈당 조절과 항산화 효과가 있습니다.",
            caution: "공복 섭취 시 위장 장애가 있을 수 있습니다.",
            method: "식전 공복에 하루 1회 섭취하세요."
        ),
        "종합비타민": SupplementInfo(
            name: "종합비타민",
            function: "일일 필수 영양소를 균형 있게 공급합니다.",
            caution: "비타민 A, D의 과다 복용에 유의하세요.",
            method: "하루 1정, 식사와 함께 섭취하세요."
        ),
        "코엔자임 Q10": SupplementInfo(
            name: "코엔자임 Q10",
            function: "에너지 생성과 심장 건강에 도움을 줍니다.",
            caution: "혈압약 복용 중이라면 의사와 상담하세요.",
            method: "하루 1회 식후에 섭취하세요."
        )
    ]
}
