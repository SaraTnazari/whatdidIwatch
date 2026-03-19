import Foundation

struct AppLanguage: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let nativeName: String
    let isRTL: Bool
    let examplePills: [String]

    init(code: String, name: String, nativeName: String, isRTL: Bool = false, pills: [String] = []) {
        self.id = code
        self.code = code
        self.name = name
        self.nativeName = nativeName
        self.isRTL = isRTL
        self.examplePills = pills
    }

    func hash(into hasher: inout Hasher) { hasher.combine(code) }
    static func == (lhs: AppLanguage, rhs: AppLanguage) -> Bool { lhs.code == rhs.code }
}

extension AppLanguage {
    static let all: [AppLanguage] = [
        .english, .spanish, .french, .german, .portuguese, .italian, .russian,
        .arabic, .persian, .hindi, .chinese, .japanese, .korean, .turkish,
        .indonesian, .thai, .vietnamese, .polish, .dutch, .swedish
    ]

    static let english = AppLanguage(code: "en", name: "English", nativeName: "English", pills: ["kids with spinning battle tops", "blue hedgehog collecting rings", "guy stuck in the same day over and over", "teenagers with notebooks that kill people", "small green alien teaches a farm boy", "fish looking for his son"])
    static let spanish = AppLanguage(code: "es", name: "Spanish", nativeName: "Español", pills: ["niños con trompos de batalla", "erizo azul recogiendo anillos", "tipo atrapado en el mismo día", "adolescentes con cuadernos que matan", "alien verde pequeño enseña a un chico", "pez buscando a su hijo"])
    static let french = AppLanguage(code: "fr", name: "French", nativeName: "Français", pills: ["enfants avec des toupies de combat", "hérisson bleu qui collecte des anneaux", "homme coincé dans la même journée", "ados avec des cahiers qui tuent", "petit alien vert qui enseigne", "poisson cherchant son fils"])
    static let german = AppLanguage(code: "de", name: "German", nativeName: "Deutsch", pills: ["Kinder mit Kampfkreiseln", "blauer Igel sammelt Ringe", "Mann im gleichen Tag gefangen", "Teenager mit tödlichen Notizbüchern", "kleiner grüner Alien als Lehrer", "Fisch sucht seinen Sohn"])
    static let portuguese = AppLanguage(code: "pt", name: "Portuguese", nativeName: "Português", pills: ["crianças com piões de batalha", "ouriço azul coletando anéis", "cara preso no mesmo dia", "adolescentes com cadernos que matam", "alien verde pequeno ensinando", "peixe procurando seu filho"])
    static let italian = AppLanguage(code: "it", name: "Italian", nativeName: "Italiano", pills: ["bambini con trottole da battaglia", "riccio blu che raccoglie anelli", "uomo intrappolato nello stesso giorno", "ragazzi con quaderni che uccidono", "piccolo alieno verde insegnante", "pesce che cerca suo figlio"])
    static let russian = AppLanguage(code: "ru", name: "Russian", nativeName: "Русский", pills: ["дети с боевыми волчками", "синий ёжик собирает кольца", "парень застрял в одном дне", "подростки со смертельными тетрадями", "маленький зелёный инопланетянин", "рыба ищет сына"])
    static let arabic = AppLanguage(code: "ar", name: "Arabic", nativeName: "العربية", isRTL: true, pills: ["ولاد عندهم بلابل بتتقاتل", "قنفذ أزرق يجمع حلقات", "واحد عالق في نفس اليوم", "مراهقين عندهم دفاتر تقتل", "كائن فضائي أخضر يعلم ولد", "سمكة تدور على ابنها"])
    static let persian = AppLanguage(code: "fa", name: "Persian", nativeName: "فارسی", isRTL: true, pills: ["بچه‌ها با فرفره‌های جنگی", "جوجه تیغی آبی که حلقه جمع می‌کنه", "یارو گیر کرده توی همون روز", "نوجوونا با دفترچه‌هایی که آدم می‌کشن", "موجود فضایی سبز کوچولو", "ماهی که دنبال پسرشه"])
    static let hindi = AppLanguage(code: "hi", name: "Hindi", nativeName: "हिन्दी", pills: ["लड़ाई के लट्टू वाले बच्चे", "अंगूठियां इकट्ठा करता नीला हेजहॉग", "उसी दिन में फंसा आदमी", "मारने वाली कॉपी वाले किशोर", "छोटा हरा एलियन सिखाता है", "बेटे को ढूंढती मछली"])
    static let chinese = AppLanguage(code: "zh", name: "Chinese", nativeName: "中文", pills: ["孩子们用陀螺战斗", "蓝色刺猬收集戒指", "男人困在同一天", "用笔记本杀人的少年", "小绿色外星人当老师", "鱼找儿子"])
    static let japanese = AppLanguage(code: "ja", name: "Japanese", nativeName: "日本語", pills: ["回転するコマで戦う子供たち", "リングを集める青いハリネズミ", "同じ日を繰り返す男", "人を殺すノートを持つ高校生", "農家の少年に教える小さな緑のエイリアン", "息子を探す魚"])
    static let korean = AppLanguage(code: "ko", name: "Korean", nativeName: "한국어", pills: ["배틀 팽이로 싸우는 아이들", "링을 모으는 파란 고슴도치", "같은 날에 갇힌 남자", "사람을 죽이는 노트를 가진 학생들", "농장 소년을 가르치는 초록 외계인", "아들을 찾는 물고기"])
    static let turkish = AppLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe", pills: ["savaş topuçlu çocuklar", "halka toplayan mavi kirpi", "aynı günde kalan adam", "öldüren defterli gençler", "küçük yeşil uzaylı öğretmen", "oğlunu arayan balık"])
    static let indonesian = AppLanguage(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", pills: ["anak-anak dengan gasing bertarung", "landak biru mengumpulkan cincin", "pria terjebak di hari yang sama", "remaja dengan buku catatan pembunuh", "alien hijau kecil mengajar", "ikan mencari anaknya"])
    static let thai = AppLanguage(code: "th", name: "Thai", nativeName: "ไทย", pills: ["เด็กๆ กับลูกข่างต่อสู้", "เม่นสีฟ้าเก็บแหวน", "ผู้ชายติดอยู่ในวันเดิม", "วัยรุ่นกับสมุดสังหาร", "เอเลี่ยนเขียวตัวเล็กสอน", "ปลาตามหาลูก"])
    static let vietnamese = AppLanguage(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", pills: ["trẻ em với con quay chiến đấu", "nhím xanh thu thập nhẫn", "người mắc kẹt cùng ngày", "thiếu niên với sổ tay giết người", "người ngoài hành tinh xanh nhỏ", "cá tìm con"])
    static let polish = AppLanguage(code: "pl", name: "Polish", nativeName: "Polski", pills: ["dzieci z bączkami bojowymi", "niebieski jeż zbiera pierścienie", "facet utknął w tym samym dniu", "nastolatkowie ze śmiertelnymi notatnikami", "mały zielony kosmita uczy", "ryba szuka syna"])
    static let dutch = AppLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands", pills: ["kinderen met gevechtstollen", "blauwe egel verzamelt ringen", "man vast in dezelfde dag", "tieners met dodelijke notitieboekjes", "klein groen buitenaards wezen", "vis zoekt zijn zoon"])
    static let swedish = AppLanguage(code: "sv", name: "Swedish", nativeName: "Svenska", pills: ["barn med stridssnurror", "blå igelkott samlar ringar", "man fast i samma dag", "tonåringar med dödliga anteckningsböcker", "liten grön utomjording undervisar", "fisk letar efter sin son"])
}
