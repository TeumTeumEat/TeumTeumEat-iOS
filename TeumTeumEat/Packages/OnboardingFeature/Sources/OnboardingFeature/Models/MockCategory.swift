//
//  MockCategory.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/29/25.
//

import Foundation


struct CategoryHierarchy {
    let main: MainCategory
    let subs: [SubCategory]
}

struct SubCategoryHierarchy {
    let sub: SubCategory
    let details: [DetailCategory]
}

// MARK: - Main Category (1단계)
enum MainCategory: String, CaseIterable, Codable, Equatable {
    case appDeveloper = "앱개발자"
    case webDeveloper = "웹개발자"
    case backDeveloper = "서버개발자"
    case designer = "디자이너"
    case planner = "PM"

    
    var subCategories: [SubCategory] {
        switch self {
        case .appDeveloper:
            return [.webDev, .appDev, .aiMl, .backend]
        case .designer:
            return [.uiux, .graphic, .productDesign]
        case .planner:
            return [.servicePlanning, .productPlanning, .businessPlanning]
        case .webDeveloper:
            return [.strategy, .operations, .finance]
        case .backDeveloper:
            return [.digital, .brand, .growth]
        }
    }
    
    var icon: String {
        switch self {
        case .appDeveloper: return "phone"
        case .designer: return "palette"
        case .planner: return "note"
        case .webDeveloper: return "web"
        case .backDeveloper: return "pm"
        }
    }
}

// MARK: - Sub Category (2단계)
enum SubCategory: String, Codable, Equatable {
    // Developer
    case webDev = "웹 개발"
    case appDev = "앱 개발"
    case aiMl = "AI/ML"
    case backend = "백엔드"
    
    // Designer
    case uiux = "UI/UX 디자인"
    case graphic = "그래픽 디자인"
    case productDesign = "프로덕트 디자인"
    
    // Planner
    case servicePlanning = "서비스 기획"
    case productPlanning = "프로덕트 기획"
    case businessPlanning = "비즈니스 기획"
    
    // Business
    case strategy = "전략"
    case operations = "운영"
    case finance = "재무"
    
    // Marketing
    case digital = "디지털 마케팅"
    case brand = "브랜드 마케팅"
    case growth = "그로스 해킹"
    
    var detailCategories: [DetailCategory] {
        switch self {
        case .webDev:
            return [.react, .vue, .angular, .nextjs]
        case .appDev:
            return [.ios, .android, .flutter, .reactNative]
        case .aiMl:
            return [.python, .tensorflow, .pytorch, .dataScience]
        case .backend:
            return [.nodejs, .java, .springBoot, .django]
        case .uiux:
            return [.figma, .sketch, .userResearch, .prototyping]
        case .graphic:
            return [.illustrator, .photoshop, .branding]
        case .productDesign:
            return [.designSystem, .interaction, .motion]
        case .servicePlanning:  //
            return [.userFlow, .wireframe, .roadmap]
        case .productPlanning:  //
            return [.mvp, .abTesting, .analytics]
        case .businessPlanning:  //
            return [.bmCanvas, .financial, .partnership]
        case .strategy:
            return [.swot, .okr, .kpi]
        case .operations:
            return [.process, .automation, .efficiency]
        case .finance:
            return [.accounting, .investment, .budget]
        case .digital:
            return [.seo, .sem, .socialMedia]
        case .brand:
            return [.positioning, .messaging, .campaign]
        case .growth:
            return [.acquisition, .retention, .viral]
        }
    }
}

// MARK: - Detail Category (3단계)
enum DetailCategory: String, Codable, Equatable {
    // Web Dev
    case react = "React"
    case vue = "Vue"
    case angular = "Angular"
    case nextjs = "Next.js"
    
    // App Dev
    case ios = "iOS/Swift"
    case android = "Android/Kotlin"
    case flutter = "Flutter"
    case reactNative = "React Native"
    
    // AI/ML
    case python = "Python"
    case tensorflow = "TensorFlow"
    case pytorch = "PyTorch"
    case dataScience = "데이터 사이언스"
    
    // Backend
    case nodejs = "Node.js"
    case java = "Java"
    case springBoot = "Spring Boot"
    case django = "Django"
    
    // UI/UX
    case figma = "Figma"
    case sketch = "Sketch"
    case userResearch = "사용자 리서치"
    case prototyping = "프로토타이핑"
    
    // Graphic
    case illustrator = "Illustrator"
    case photoshop = "Photoshop"
    case branding = "브랜딩"
    
    // Product Design
    case designSystem = "디자인 시스템"
    case interaction = "인터랙션"
    case motion = "모션 디자인"
    
    // Service Planning
    case userFlow = "유저 플로우"
    case wireframe = "와이어프레임"
    case roadmap = "로드맵"
    
    // Product Planning
    case mvp = "MVP"
    case abTesting = "A/B 테스팅"
    case analytics = "데이터 분석"
    
    // Business Planning
    case bmCanvas = "비즈니스 모델 캔버스"
    case financial = "재무 분석"
    case partnership = "파트너십"
    
    // Strategy
    case swot = "SWOT 분석"
    case okr = "OKR"
    case kpi = "KPI"
    
    // Operations
    case process = "프로세스 개선"
    case automation = "자동화"
    case efficiency = "효율화"
    
    // Finance
    case accounting = "회계"
    case investment = "투자"
    case budget = "예산 관리"
    
    // Digital Marketing
    case seo = "SEO"
    case sem = "SEM"
    case socialMedia = "소셜 미디어"
    
    // Brand Marketing
    case positioning = "포지셔닝"
    case messaging = "메시징"
    case campaign = "캠페인"
    
    // Growth
    case acquisition = "유저 획득"
    case retention = "리텐션"
    case viral = "바이럴"
}
