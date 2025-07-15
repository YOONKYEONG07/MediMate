import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
//                    Text("개인정보 처리방침")
//                        .font(.title)
//                        .bold()
//                        .padding(.bottom, 10)

                    Group {
                        Text("1. 수집하는 개인정보 항목")
                            .font(.headline)
                        Text("""
- 필수 수집 항목:
  • 이메일 주소 (회원가입 및 로그인 시)
  • 닉네임 또는 사용자 이름
- 선택 수집 항목:
  • 감정 기록, 복약 일지 등 사용자가 입력한 건강/기록 데이터
- 자동 수집 항목:
  • 앱 이용 로그, 접속 기기 정보(OS, 버전 등), 에러 로그
""")
                    }
                    
                    Group {
                        Text("2. 개인정보 수집 및 이용 목적")
                            .font(.headline)
                        Text("""
- 회원가입 및 사용자 식별
- 개인 맞춤형 복약/감정 관리 기능 제공
- 문의 응대 및 앱 이용 관련 공지사항 전달
- 앱 기능 개선 및 서비스 운영 분석
""")
                    }

                    Group {
                        Text("3. 개인정보 보유 및 이용 기간")
                            .font(.headline)
                        Text("""
- 회원 탈퇴 시 모든 개인정보는 즉시 삭제됩니다.
- 단, 관련 법령에 따라 일정 기간 보존이 필요한 경우에는 해당 법률을 따릅니다.
""")
                    }

                    Group {
                        Text("4. 개인정보 제3자 제공")
                            .font(.headline)
                        Text("""
- MediMate는 원칙적으로 개인정보를 외부에 제공하지 않습니다.
- 단, 다음의 경우는 예외로 합니다:
  • 사용자의 동의를 받은 경우
  • 법령에 의거하거나 수사기관의 요청이 있는 경우
""")
                    }

                    Group {
                        Text("5. 개인정보 처리 위탁")
                            .font(.headline)
                        Text("""
- Firebase (서버 및 인증 처리)
- Cloud provider (데이터 저장 및 백업)
""")
                    }

                    Group {
                        Text("6. 사용자의 권리와 행사 방법")
                            .font(.headline)
                        Text("""
- 개인정보 열람, 수정, 삭제, 처리 정지를 요청할 수 있습니다.
- 탈퇴는 앱 내 마이페이지 또는 문의 메일을 통해 신청할 수 있습니다.
""")
                    }

                    Group {
                        Text("7. 개인정보 보호 책임자")
                            .font(.headline)
                        Text("""
- 책임자: MediMate 팀
- 이메일: medimate.help@gmail.com
""")
                    }

                    Group {
                        Text("8. 변경에 대한 고지")
                            .font(.headline)
                        Text("""
- 본 방침은 변경될 수 있으며, 변경 시 앱 내 공지 또는 이메일을 통해 고지됩니다.
- 시행일자: 2025년 7월 15일
""")
                    }
                }
                .padding()
            }
            .navigationTitle("개인정보 처리방침")
        }
    }
}
