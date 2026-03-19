//
//  LocalizationManager.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "selectedLanguage")
            objectWillChange.send()
        }
    }
    
    private init() {
        // Load saved language or use device language
        if let savedCode = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage.allCases.first(where: { $0.code == savedCode }) {
            self.currentLanguage = language
        } else {
            // Default to device language if available, otherwise English
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = AppLanguage.allCases.first(where: { $0.code == deviceLanguage }) ?? .english
        }
    }
    
    func localized(_ key: String) -> String {
        return LocalizedStrings.get(key, language: currentLanguage)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Español"
    case french = "Français"
    case german = "Deutsch"
    case italian = "Italiano"
    case portuguese = "Português"
    case japanese = "日本語"
    case korean = "한국어"
    case chinese = "中文"
    case arabic = "العربية"
    case russian = "Русский"
    case hindi = "हिन्दी"
    case dutch = "Nederlands"
    case turkish = "Türkçe"
    case polish = "Polski"
    case swedish = "Svenska"
    case norwegian = "Norsk"
    case danish = "Dansk"
    case finnish = "Suomi"
    case greek = "Ελληνικά"
    case thai = "ไทย"
    case vietnamese = "Tiếng Việt"
    case indonesian = "Bahasa Indonesia"
    case malay = "Bahasa Melayu"
    case tagalog = "Tagalog"
    case czech = "Čeština"
    case hungarian = "Magyar"
    case romanian = "Română"
    case hebrew = "עברית"
    case ukrainian = "Українська"
    case bengali = "বাংলা"
    
    var id: String { rawValue }
    
    var code: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .chinese: return "zh"
        case .arabic: return "ar"
        case .russian: return "ru"
        case .hindi: return "hi"
        case .dutch: return "nl"
        case .turkish: return "tr"
        case .polish: return "pl"
        case .swedish: return "sv"
        case .norwegian: return "no"
        case .danish: return "da"
        case .finnish: return "fi"
        case .greek: return "el"
        case .thai: return "th"
        case .vietnamese: return "vi"
        case .indonesian: return "id"
        case .malay: return "ms"
        case .tagalog: return "tl"
        case .czech: return "cs"
        case .hungarian: return "hu"
        case .romanian: return "ro"
        case .hebrew: return "he"
        case .ukrainian: return "uk"
        case .bengali: return "bn"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        case .russian: return "🇷🇺"
        case .hindi: return "🇮🇳"
        case .dutch: return "🇳🇱"
        case .turkish: return "🇹🇷"
        case .polish: return "🇵🇱"
        case .swedish: return "🇸🇪"
        case .norwegian: return "🇳🇴"
        case .danish: return "🇩🇰"
        case .finnish: return "🇫🇮"
        case .greek: return "🇬🇷"
        case .thai: return "🇹🇭"
        case .vietnamese: return "🇻🇳"
        case .indonesian: return "🇮🇩"
        case .malay: return "🇲🇾"
        case .tagalog: return "🇵🇭"
        case .czech: return "🇨🇿"
        case .hungarian: return "🇭🇺"
        case .romanian: return "🇷🇴"
        case .hebrew: return "🇮🇱"
        case .ukrainian: return "🇺🇦"
        case .bengali: return "🇧🇩"
        }
    }
}

// Localized strings dictionary
struct LocalizedStrings {
    static func get(_ key: String, language: AppLanguage) -> String {
        let translations: [String: [AppLanguage: String]] = [
            // Navigation & Common
            "app_name": [
                .english: "Travel Buddy",
                .spanish: "Compañero de Viaje",
                .french: "Compagnon de Voyage",
                .german: "Reisebegleiter",
                .italian: "Compagno di Viaggio",
                .portuguese: "Companheiro de Viagem",
                .japanese: "旅行仲間",
                .korean: "여행 친구",
                .chinese: "旅行伙伴",
                .arabic: "رفيق السفر",
                .russian: "Попутчик",
                .hindi: "यात्रा साथी",
                .dutch: "Reismaatje",
                .turkish: "Seyahat Arkadaşı",
                .polish: "Towarzysz Podróży",
                .swedish: "Resekompis",
                .norwegian: "Reisekamerat",
                .danish: "Rejsekammerat",
                .finnish: "Matkakumppani",
                .greek: "Ταξιδιωτικός Σύντροφος",
                .thai: "เพื่อนร่วมทาง",
                .vietnamese: "Bạn Đồng Hành",
                .indonesian: "Teman Perjalanan",
                .malay: "Rakan Perjalanan",
                .tagalog: "Kasama sa Biyahe",
                .czech: "Cestovní Kamarád",
                .hungarian: "Utazótárs",
                .romanian: "Companion de Călătorie",
                .hebrew: "חבר מסע",
                .ukrainian: "Супутник",
                .bengali: "ভ্রমণ সঙ্গী"
            ],
            "new_trip": [
                .english: "New Trip",
                .spanish: "Nuevo Viaje",
                .french: "Nouveau Voyage",
                .german: "Neue Reise",
                .italian: "Nuovo Viaggio",
                .portuguese: "Nova Viagem",
                .japanese: "新しい旅行",
                .korean: "새 여행",
                .chinese: "新旅行",
                .arabic: "رحلة جديدة",
                .russian: "Новая поездка",
                .hindi: "नई यात्रा",
                .dutch: "Nieuwe Reis",
                .turkish: "Yeni Gezi",
                .polish: "Nowa Podróż",
                .swedish: "Ny Resa",
                .norwegian: "Ny Reise",
                .danish: "Ny Rejse",
                .finnish: "Uusi Matka",
                .greek: "Νέο Ταξίδι",
                .thai: "ทริปใหม่",
                .vietnamese: "Chuyến Đi Mới",
                .indonesian: "Perjalanan Baru",
                .malay: "Perjalanan Baharu",
                .tagalog: "Bagong Biyahe",
                .czech: "Nová Cesta",
                .hungarian: "Új Utazás",
                .romanian: "Călătorie Nouă",
                .hebrew: "טיול חדש",
                .ukrainian: "Нова Подорож",
                .bengali: "নতুন ভ্রমণ"
            ],
            "create_trip": [
                .english: "Create Trip",
                .spanish: "Crear Viaje",
                .french: "Créer un Voyage",
                .german: "Reise Erstellen",
                .italian: "Crea Viaggio",
                .portuguese: "Criar Viagem",
                .japanese: "旅行を作成",
                .korean: "여행 만들기",
                .chinese: "创建旅行",
                .arabic: "إنشاء رحلة",
                .russian: "Создать поездку",
                .hindi: "यात्रा बनाएं"
            ],
            "trip_name": [
                .english: "Trip Name",
                .spanish: "Nombre del Viaje",
                .french: "Nom du Voyage",
                .german: "Reisename",
                .italian: "Nome del Viaggio",
                .portuguese: "Nome da Viagem",
                .japanese: "旅行名",
                .korean: "여행 이름",
                .chinese: "旅行名称",
                .arabic: "اسم الرحلة",
                .russian: "Название поездки",
                .hindi: "यात्रा का नाम"
            ],
            "start_date": [
                .english: "Start Date",
                .spanish: "Fecha de Inicio",
                .french: "Date de Début",
                .german: "Startdatum",
                .italian: "Data di Inizio",
                .portuguese: "Data de Início",
                .japanese: "開始日",
                .korean: "시작일",
                .chinese: "开始日期",
                .arabic: "تاريخ البدء",
                .russian: "Дата начала",
                .hindi: "प्रारंभ तिथि"
            ],
            "end_date": [
                .english: "End Date",
                .spanish: "Fecha de Fin",
                .french: "Date de Fin",
                .german: "Enddatum",
                .italian: "Data di Fine",
                .portuguese: "Data de Término",
                .japanese: "終了日",
                .korean: "종료일",
                .chinese: "结束日期",
                .arabic: "تاريخ الانتهاء",
                .russian: "Дата окончания",
                .hindi: "समाप्ति तिथि"
            ],
            "currency": [
                .english: "Currency",
                .spanish: "Moneda",
                .french: "Devise",
                .german: "Währung",
                .italian: "Valuta",
                .portuguese: "Moeda",
                .japanese: "通貨",
                .korean: "통화",
                .chinese: "货币",
                .arabic: "العملة",
                .russian: "Валюта",
                .hindi: "मुद्रा"
            ],
            "settings": [
                .english: "Settings",
                .spanish: "Configuración",
                .french: "Paramètres",
                .german: "Einstellungen",
                .italian: "Impostazioni",
                .portuguese: "Configurações",
                .japanese: "設定",
                .korean: "설정",
                .chinese: "设置",
                .arabic: "الإعدادات",
                .russian: "Настройки",
                .hindi: "सेटिंग्स",
                .dutch: "Instellingen",
                .turkish: "Ayarlar",
                .polish: "Ustawienia",
                .swedish: "Inställningar",
                .norwegian: "Innstillinger",
                .danish: "Indstillinger",
                .finnish: "Asetukset",
                .greek: "Ρυθμίσεις",
                .thai: "การตั้งค่า",
                .vietnamese: "Cài Đặt",
                .indonesian: "Pengaturan",
                .malay: "Tetapan",
                .tagalog: "Mga Setting",
                .czech: "Nastavení",
                .hungarian: "Beállítások",
                .romanian: "Setări",
                .hebrew: "הגדרות",
                .ukrainian: "Налаштування",
                .bengali: "সেটিংস"
            ],
            "language": [
                .english: "Language",
                .spanish: "Idioma",
                .french: "Langue",
                .german: "Sprache",
                .italian: "Lingua",
                .portuguese: "Idioma",
                .japanese: "言語",
                .korean: "언어",
                .chinese: "语言",
                .arabic: "اللغة",
                .russian: "Язык",
                .hindi: "भाषा",
                .dutch: "Taal",
                .turkish: "Dil",
                .polish: "Język",
                .swedish: "Språk",
                .norwegian: "Språk",
                .danish: "Sprog",
                .finnish: "Kieli",
                .greek: "Γλώσσα",
                .thai: "ภาษา",
                .vietnamese: "Ngôn Ngữ",
                .indonesian: "Bahasa",
                .malay: "Bahasa",
                .tagalog: "Wika",
                .czech: "Jazyk",
                .hungarian: "Nyelv",
                .romanian: "Limbă",
                .hebrew: "שפה",
                .ukrainian: "Мова",
                .bengali: "ভাষা"
            ],
            "active_trips": [
                .english: "Active Trips",
                .spanish: "Viajes Activos",
                .french: "Voyages Actifs",
                .german: "Aktive Reisen",
                .italian: "Viaggi Attivi",
                .portuguese: "Viagens Ativas",
                .japanese: "アクティブな旅行",
                .korean: "활성 여행",
                .chinese: "活跃旅行",
                .arabic: "الرحلات النشطة",
                .russian: "Активные поездки",
                .hindi: "सक्रिय यात्राएं"
            ],
            "past_trips": [
                .english: "Past Trips",
                .spanish: "Viajes Pasados",
                .french: "Voyages Passés",
                .german: "Vergangene Reisen",
                .italian: "Viaggi Passati",
                .portuguese: "Viagens Passadas",
                .japanese: "過去の旅行",
                .korean: "지난 여행",
                .chinese: "过去的旅行",
                .arabic: "الرحلات السابقة",
                .russian: "Прошлые поездки",
                .hindi: "पिछली यात्राएं"
            ],
            "expenses": [
                .english: "Expenses",
                .spanish: "Gastos",
                .french: "Dépenses",
                .german: "Ausgaben",
                .italian: "Spese",
                .portuguese: "Despesas",
                .japanese: "経費",
                .korean: "지출",
                .chinese: "费用",
                .arabic: "المصروفات",
                .russian: "Расходы",
                .hindi: "खर्चे"
            ],
            "buddies": [
                .english: "Buddies",
                .spanish: "Compañeros",
                .french: "Compagnons",
                .german: "Freunde",
                .italian: "Compagni",
                .portuguese: "Companheiros",
                .japanese: "仲間",
                .korean: "친구들",
                .chinese: "伙伴",
                .arabic: "الرفاق",
                .russian: "Друзья",
                .hindi: "साथी"
            ],
            "itinerary": [
                .english: "Itinerary",
                .spanish: "Itinerario",
                .french: "Itinéraire",
                .german: "Reiseplan",
                .italian: "Itinerario",
                .portuguese: "Itinerário",
                .japanese: "旅程",
                .korean: "여정",
                .chinese: "行程",
                .arabic: "خط السير",
                .russian: "Маршрут",
                .hindi: "यात्रा कार्यक्रम"
            ],
            "payments": [
                .english: "Payments",
                .spanish: "Pagos",
                .french: "Paiements",
                .german: "Zahlungen",
                .italian: "Pagamenti",
                .portuguese: "Pagamentos",
                .japanese: "支払い",
                .korean: "결제",
                .chinese: "付款",
                .arabic: "المدفوعات",
                .russian: "Платежи",
                .hindi: "भुगतान"
            ],
            "summary": [
                .english: "Summary",
                .spanish: "Resumen",
                .french: "Résumé",
                .german: "Zusammenfassung",
                .italian: "Riepilogo",
                .portuguese: "Resumo",
                .japanese: "概要",
                .korean: "요약",
                .chinese: "摘要",
                .arabic: "ملخص",
                .russian: "Сводка",
                .hindi: "सारांश"
            ],
            "delete": [
                .english: "Delete",
                .spanish: "Eliminar",
                .french: "Supprimer",
                .german: "Löschen",
                .italian: "Elimina",
                .portuguese: "Excluir",
                .japanese: "削除",
                .korean: "삭제",
                .chinese: "删除",
                .arabic: "حذف",
                .russian: "Удалить",
                .hindi: "हटाएं"
            ],
            "archive": [
                .english: "Archive",
                .spanish: "Archivar",
                .french: "Archiver",
                .german: "Archivieren",
                .italian: "Archivia",
                .portuguese: "Arquivar",
                .japanese: "アーカイブ",
                .korean: "보관",
                .chinese: "归档",
                .arabic: "أرشفة",
                .russian: "Архивировать",
                .hindi: "संग्रहित करें"
            ],
            "restore": [
                .english: "Restore",
                .spanish: "Restaurar",
                .french: "Restaurer",
                .german: "Wiederherstellen",
                .italian: "Ripristina",
                .portuguese: "Restaurar",
                .japanese: "復元",
                .korean: "복원",
                .chinese: "恢复",
                .arabic: "استعادة",
                .russian: "Восстановить",
                .hindi: "पुनर्स्थापित करें"
            ],
            "days": [
                .english: "days",
                .spanish: "días",
                .french: "jours",
                .german: "Tage",
                .italian: "giorni",
                .portuguese: "dias",
                .japanese: "日",
                .korean: "일",
                .chinese: "天",
                .arabic: "أيام",
                .russian: "дней",
                .hindi: "दिन"
            ],
            "total": [
                .english: "Total",
                .spanish: "Total",
                .french: "Total",
                .german: "Gesamt",
                .italian: "Totale",
                .portuguese: "Total",
                .japanese: "合計",
                .korean: "총",
                .chinese: "总计",
                .arabic: "المجموع",
                .russian: "Всего",
                .hindi: "कुल"
            ]
        ]
        
        return translations[key]?[language] ?? key
    }
}
