import Foundation
import AppKit

struct ANSI: Decodable {
    let enable: Bool?
    let colors: [String:String]?
}

struct Cursor: Decodable {
    let type: String?
    let color: String?
    let blink: Bool?
}

struct InactiveSettings: Decodable {
    let enable: Bool?
    let backgroundAlpha: Double?
    let backgroundBlur: Double?
}

struct Font: Decodable {
    let name: String
    let size: Double
    let antialias: Bool?
    let widthSpacing: Double?
    let fallback: [String]?
}
struct Profile: Decodable {
    let name: String
    let backgroundColor: String?
    let backgroundBlur: Double?
    let textColor: String?
    let textBoldColor: String?
    let selectionColor: String?
    let cursor: Cursor?
    let ansi: ANSI?
    let font: Font
    let inactiveSettings: InactiveSettings?
    let boldUsesBrightColors: Bool?
}

func parseHex(_ s: String) -> NSColor {
    var hex = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") { hex.removeFirst() }
    var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255
    if hex.count == 6 {
        Scanner(string: String(hex.prefix(2))).scanHexInt64(&r)
        Scanner(string: String(hex.dropFirst(2).prefix(2))).scanHexInt64(&g)
        Scanner(string: String(hex.dropFirst(4).prefix(2))).scanHexInt64(&b)
    } else if hex.count == 8 {
        Scanner(string: String(hex.prefix(2))).scanHexInt64(&r)
        Scanner(string: String(hex.dropFirst(2).prefix(2))).scanHexInt64(&g)
        Scanner(string: String(hex.dropFirst(4).prefix(2))).scanHexInt64(&b)
        Scanner(string: String(hex.dropFirst(6).prefix(2))).scanHexInt64(&a)
    } else { fatalError("Use #RRGGBB or #RRGGBBAA: \(s)") }
    return NSColor(srgbRed: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
}

func archive(_ obj: Any) -> Data {
    try! NSKeyedArchiver.archivedData(withRootObject: obj, requiringSecureCoding: false)
}

func pickFont(preferred: [String], size: CGFloat) -> NSFont {
    for name in preferred { if let f = NSFont(name: name, size: size) { return f } }
    return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
}

func cursorTypeCode(_ s: String) -> Int {
    switch s.lowercased() {
    case "block": return 0
    case "underline": return 1
    case "bar": return 3
    default: return 0
    }
}

let ansiMap: [(String,String)] = [
  ("black","ANSIBlackColor"), ("red","ANSIRedColor"), ("green","ANSIGreenColor"),
  ("yellow","ANSIYellowColor"), ("blue","ANSIBlueColor"), ("magenta","ANSIMagentaColor"),
  ("cyan","ANSICyanColor"), ("white","ANSIWhiteColor"),
  ("brightBlack","ANSIBrightBlackColor"), ("brightRed","ANSIBrightRedColor"),
  ("brightGreen","ANSIBrightGreenColor"), ("brightYellow","ANSIBrightYellowColor"),
  ("brightBlue","ANSIBrightBlueColor"), ("brightMagenta","ANSIBrightMagentaColor"),
  ("brightCyan","ANSIBrightCyanColor"), ("brightWhite","ANSIBrightWhiteColor"),
]

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: TerminalPack.swift /path/to/profiles.json\n", stderr); exit(2)
}

let profiles = try JSONDecoder().decode([Profile].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))

for p in profiles {
    var dict: [String:Any] = [
      "name": p.name,
      "type": "Window Settings",
      "ProfileCurrentVersion": 2.07
    ]
    func putColor(_ key: String, _ hex: String?) { if let s = hex { dict[key] = archive(parseHex(s)) } }
    putColor("BackgroundColor", p.backgroundColor)
    putColor("TextColor", p.textColor)
    putColor("TextBoldColor", p.textBoldColor)
    putColor("SelectionColor", p.selectionColor)

    if let cursor = p.cursor {
        if let cursorType = cursor.type { dict["CursorType"] = cursorTypeCode(cursorType) }
        if let hex = cursor.color { dict["CursorColor"] = archive(parseHex(hex)) }
        if let blink = cursor.blink { dict["CursorBlink"] = blink }
    }


    if let backgroundBlur = p.backgroundBlur  { dict["BackgroundBlur"]  = backgroundBlur }

    if let inact = p.inactiveSettings {
        let enabled = inact.enable ?? false

        dict["BackgroundSettingsForInactiveWindows"] = enabled ? 1 : 0

        if let inactiveAlpha = inact.backgroundAlpha { dict["BackgroundAlphaInactive"] = inactiveAlpha }
        if let inactiveBlur = inact.backgroundBlur  { dict["BackgroundBlurInactive"]  = inactiveBlur }
    }

    if let ansi = p.ansi {
        if let en = ansi.enable, en == false {
            dict["DisableANSIColor"] = 1
        }
        if let colors = ansi.colors {
            for (nice, raw) in ansiMap {
                if let hex = colors[nice] {
                    dict[raw] = archive(parseHex(hex))
                }
            }
        }
    }

    if let bright = p.boldUsesBrightColors { dict["UseBrightBold"] = bright }

    let candidates = [p.font.name] + (p.font.fallback ?? [])
    let nsf = pickFont(preferred: candidates, size: CGFloat(p.font.size))
    dict["Font"] = archive(nsf)
    if let aa = p.font.antialias { dict["FontAntialias"] = aa }
    if let ws = p.font.widthSpacing { dict["FontWidthSpacing"] = String(ws) }

    let frag = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
    let outURL = URL(fileURLWithPath: "/tmp/\(p.name).xml")
    try frag.write(to: outURL, options: .atomic)

    print("\(p.name)\t\(outURL.path)")
}
