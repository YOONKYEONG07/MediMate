import SwiftUI

// 📘 아티클 모델
struct SupplementArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String

    let overview: String      // 기본 설명
    let effects: [String]     // 효능
    let method: [String]      // 복용법
    let caution: [String]     // 주의사항
    let interaction: [String] //상호작용
}

let supplementArticles: [SupplementArticle] = [
    SupplementArticle(
        title: "비타민 D",
        summary: "뼈 건강, 면역력 강화, 우울감 개선까지 도와주는 필수 비타민.",
        overview: "비타민 D는 지용성 비타민으로, 햇빛을 받으면 피부에서 합성됩니다. 칼슘 흡수를 도와 뼈를 튼튼하게 만들며, 면역 기능과 기분 조절에도 관여합니다.",
        effects: [
            "뼈 건강 및 골다공증 예방",
            "면역력 강화",
            "우울감 완화",
            "심혈관 질환 예방 가능성"
        ],
        method: [
            "일반 권장량: 600~800 IU",
            "결핍 시 1000~2000 IU 복용",
            "식후에 복용 시 흡수율 증가"
        ],
        caution: [
            "고용량 복용 시 신장결석 등 부작용",
            "장기 복용 전 의사 상담 필요"
        ],
        interaction: [
            "칼슘과 함께 복용 시 시너지",
            "스테로이드, 항경련제와 상호작용"
        ]
    ),
    SupplementArticle(
        title: "오메가3",
        summary: "EPA, DHA로 구성된 오메가-3는 뇌 건강과 혈액순환에 효과적입니다.",
        overview: "오메가-3는 불포화지방산으로 체내 합성이 어려워 외부 섭취가 필요합니다. 주로 생선에서 추출되며, EPA와 DHA 형태로 보충제 사용이 많습니다.",
        effects: [
            "심혈관 질환 예방",
            "혈액 순환 개선",
            "뇌 기능 강화 (집중력, 기억력)",
            "항염 효과, 눈 건강 개선"
        ],
        method: [
            "권장량: 500~1000mg (EPA+DHA 합산)",
            "식후 복용 권장 (흡수율 ↑)"
        ],
        caution: [
            "고용량 섭취 시 출혈 위험",
            "비린내, 역류감 등 있을 수 있음"
        ],
        interaction: [
            "항응고제(아스피린 등)와 병용 시 주의",
            "일부 혈압약과 저혈압 유발 가능"
        ]
    ),
    SupplementArticle(
        title: "유산균 - 장 속부터 건강을 지키는 미생물",
        summary: "장 건강과 면역력 강화에 탁월한 프로바이오틱스.",
        overview: "프로바이오틱스는 장내 유익균으로, 소화기 및 면역 건강에 기여합니다. 락토바실러스, 비피도박테리움 등의 균주가 대표적입니다.",
        effects: [
            "장 건강 개선 (변비, 설사)",
            "면역력 증진",
            "피부 트러블 개선",
            "구강, 질 건강 도움"
        ],
        method: [
            "식후 또는 잠들기 전 복용 권장",
            "꾸준한 섭취가 핵심"
        ],
        caution: [
            "항생제 복용 시 간격 두기",
            "일부 가스, 복부 팽만감 초기 발생"
        ],
        interaction: [
            "항생제, 면역억제제와 병용 시 주의"
        ]
    ),
    SupplementArticle(
        title: "멀티비타민 - 한 알로 챙기는 영양 밸런스",
        summary: "비타민과 미네랄을 종합적으로 담은 만능 영양제.",
        overview: "멀티비타민은 다양한 비타민과 미네랄을 복합적으로 섭취할 수 있는 영양제입니다. 바쁜 현대인의 영양 불균형을 보완하는 데 유용합니다.",
        effects: [
            "전반적인 영양 보충",
            "피로 개선, 면역력 강화",
            "피부 건강, 항산화 효과"
        ],
        method: [
            "하루 1~2회, 식사 직후 복용",
            "커피/차와 함께 복용 금지"
        ],
        caution: [
            "지용성 비타민 과잉 시 독성 가능성",
            "중복 섭취 주의"
        ],
        interaction: [
            "철분, 아연, 마그네슘 → 커피·차와 동시 복용 금지",
            "항응고제 복용 중일 경우 비타민 K 주의"
        ]
    ),
    SupplementArticle(
        title: "마그네슘 - 몸과 마음을 이완시키는 미네랄",
        summary: "근육과 신경 안정, 수면에 도움을 주는 필수 미네랄.",
        overview: "마그네슘은 신경, 근육, 심장 기능에 꼭 필요한 미네랄입니다. 현대인은 스트레스와 식습관으로 인해 결핍되기 쉬운 성분입니다.",
        effects: [
            "근육 이완 및 경련 완화",
            "숙면 유도, 신경 안정",
            "편두통 완화, 심장 건강"
        ],
        method: [
            "성인 권장량: 300~400mg",
            "자기 전 또는 식후 복용",
            "글리시네이트/시트레이트/산화형 등 다양"
        ],
        caution: [
            "과잉 섭취 시 설사, 저혈압, 무기력",
            "신장질환자는 복용 금지"
        ],
        interaction: [
            "항생제, 이뇨제, 심장약 등과 상호작용",
            "철분·아연과는 간격 두고 복용"
        ]
    )
]



struct SupplementRecommendationView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 🟩 건강 상태 체크 카드
                HealthSurveyStartCard()

                // 📄 아티클 섹션 타이틀
                Text("추천 영양제 아티클")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                // 📄 아티클 카드 리스트
                ForEach(supplementArticles) { article in
                    SupplementArticleCard(article: article, selectedTab: $selectedTab)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("맞춤 영양제 추천")
    }
}

