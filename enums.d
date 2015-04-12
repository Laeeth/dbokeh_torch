module dbokeh.enums;
import std.regex;
import std.conv;
import std.exception;

immutable string[] LineJoin=["Miter","Round","Bevel"];
immutable string[] LineCap=["Butt","Round","Square"];
immutable string[] FontStyles=["Normal","Italic","Bold"];
immutable string[] FontUnits=["EX","PX","CM","MM","IN","PT","PC"];
immutable string[] TextAlign=["Left","Right","Center"];
immutable string[] TextBaseline=["Top","Middle","Bottom","Alphabetic","Hanging"];
immutable string[] Direction=["Clock","AntiClock"];
immutable string[] SpatialUnits=["Data","Screen"];
immutable string[] AngularUnits=["Rad","Deg"];
immutable string[] DatetimeUnits=[  "Microseconds","Milliseconds", "Seconds", "Minsec", "Minutes", "Hourmin", "Hours",
                                    "Days", "Months", "Years"];
immutable string[] Dimension=["Width","Height"];
immutable string[] Location=["Auto","Above","Below","Left","Right"];
immutable string[] Orientation=["Horizontal","Vertical"]; //class Angle(value: Double) extends Orientation
immutable string[] LegendOrientation=["TopRight","TopLeft","BottomLeft","BottomRight"];
immutable string[] BorderSymmetry=["Horizontal","Vertical","HorizontalVertical","VerticalHorizontal"];
immutable string[] Anchor=["TopLeft","TopCenter","TopRight","RightCenter","BottomRight","BottomCenter","BottomLeft","LeftCenter","Center"];
immutable string[] ColumnType=  ["String","Numeric","Date","Checkbox","Select","Dropdown","Autocomplete","Password","Handsontable"];
immutable string[] ButtonType=  ["Default","Primary","Success","Warning","Danger","Link"];
immutable string[] MapType=     ["Satellite","Roadmap","Terrain","Hybrid"];
immutable string[] Flip =       ["Horizontal","Vertical"];
immutable string[] LogLevel=    ["Trace","Debug","Info","Warn","Error","Fatal"];
immutable string[] Checkmark=   ["Check","CheckCircle","CheckCircleO","CheckSquare","CheckSquareO"];
immutable string[] Sort=        ["Ascending","Descending"];
immutable string[] Logo=        ["Normal","Grey"];
immutable string[] Layout=      ["Left","Right","Above","Below","Center"];
immutable string[] DateFormat=  [   "ATOM","W3C","\"RFC-3339\"","\"ISO-8601\"","COOKIE","\"RFC-822\"","\"RFC-850\"",
                                    "\"RFC-1036\"","\"RFC-1123\"","\"RFC-2822\"","RSS","TIMESTAMP"];
immutable string[] RoundingFunction= [  "Round", "Nearest", "Floor", "RoundDown", "Ceil", "RoundUp"];
immutable string[] NumeralLanguage= [   "be-nl" , "chs" , "cs" , "da-dk" , "de-ch" , "de" , "en" , "en-gb" , "es-ES" , "es" , "et" ,
                                        "fi" , "fr-CA" , "fr-ch" , "fr" , "hu" , "it" , "ja" , "nl-nl" , "pl" , "pt-br" , "pt-pt" , "ru" ,
                                        "ru-UA" , "sk" , "th" , "tr" , "uk-UA"
                                    ];
immutable string[] HTTPMethod = ["POST","GET"];

immutable string[] NamedIcon = [	"Adjust", "Adn", "AlignCenter", "AlignJustify", "AlignLeft", "AlignRight", "Ambulance", "Anchor",
    								"Android", "Angellist", "AngleDoubleDown", "AngleDoubleLeft", "AngleDoubleRight", "AngleDoubleUp",
    								"AngleDown", "AngleLeft", "AngleRight", "AngleUp", "Apple", "Archive", "AreaChart", "ArrowCircleDown",
								    "ArrowCircleLeft", "ArrowCircleODown", "ArrowCircleOLeft", "ArrowCircleORight", "ArrowCircleOUp",
								    "ArrowCircleRight", "ArrowCircleUp", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowUp", "Arrows",
								    "ArrowsAlt", "ArrowsH", "ArrowsV", "Asterisk", "At", "Automobile", "Backward", "Ban", "Bank", "BarChart",
								    "BarChartO", "Barcode", "Bars", "Beer", "Behance", "BehanceSquare", "Bell", "BellO", "BellSlash",
								    "BellSlashO", "Bicycle", "Binoculars", "BirthdayCake", "Bitbucket", "BitbucketSquare", "Bitcoin",
								    "Bold", "Bolt", "Bomb", "Book", "Bookmark", "BookmarkO", "Briefcase", "Btc", "Bug", "Building", 
								    "BuildingO", "Bullhorn", "Bullseye", "Bus", "Cab", "Calculator", "Calendar", "CalendarO", "Camera",
								    "CameraRetro", "Car", "CaretDown", "CaretLeft", "CaretRight", "CaretSquareODown", "CaretSquareOLeft",
								    "CaretSquareORight", "CaretSquareOUp", "CaretUp", "Cc", "CcAmex", "CcDiscover", "CcMastercard",
								    "CcPaypal", "CcStripe", "CcVisa", "Certificate", "Chain", "ChainBroken", "Check", "CheckCircle",
								    "CheckCircleO", "CheckSquare", "CheckSquareO", "ChevronCircleDown", "ChevronCircleLeft",
								    "ChevronCircleRight", "ChevronCircleUp", "ChevronDown", "ChevronLeft", "ChevronRight", "ChevronUp",
								    "Child", "Circle", "CircleO", "CircleONotch", "CircleThin", "Clipboard", "ClockO", "Close", "Cloud",
								    "CloudDownload", "CloudUpload", "Cny", "Code", "CodeFork", "Codepen", "Coffee", "Cog", "Cogs", "Columns",
								    "Comment", "CommentO", "Comments", "CommentsO", "Compass", "Compress", "Copy", "Copyright", "CreditCard",
								    "Crop", "Crosshairs", "Css3", "Cube", "Cubes", "Cut", "Cutlery", "Dashboard", "Database", "Dedent",
								    "Delicious", "Desktop", "Deviantart", "Digg", "Dollar", "DotCircleO", "Download", "Dribbble",
								    "Dropbox", "Drupal", "Edit", "Eject", "EllipsisH", "EllipsisV", "Empire", "Envelope", "EnvelopeO",
								    "EnvelopeSquare", "Eraser", "Eur", "Euro", "Exchange", "Exclamation", "ExclamationCircle",
								    "ExclamationTriangle", "Expand", "ExternalLink", "ExternalLinkSquare", "Eye", "EyeSlash", "Eyedropper",
								    "Facebook", "FacebookSquare", "FastBackward", "FastForward", "Fax", "Female", "FighterJet", "File",
								    "FileArchiveO", "FileAudioO", "FileCodeO", "FileExcelO", "FileImageO", "FileMovieO", "FileO", 
								   	"FilePdfO", "FilePhotoO", "FilePictureO", "FilePowerpointO", "FileSoundO", "FileText", "FileTextO",
								    "FileVideoO", "FileWordO", "FileZipO", "FilesO", "Film", "Filter", "Fire", "FireExtinguisher", "Flag",
								    "FlagCheckered", "FlagO", "Flash", "Flask", "Flickr", "FloppyO", "Folder", "FolderO", "FolderOpen",
								    "FolderOpenO", "Font", "Forward", "Foursquare", "FrownO", "FutbolO", "Gamepad", "Gavel", "Gbp", "Ge",
								    "Gear", "Gears", "Gift", "Git", "GitSquare", "Github", "GithubAlt", "GithubSquare", "Gittip", "Glass",
								    "Globe", "Google", "GooglePlus", "GooglePlusSquare", "GoogleWallet", "GraduationCap", "Group", "HSquare",
								    "HackerNews", "HandODown", "HandOLeft", "HandORight", "HandOUp", "HddO", "Header", "Headphones", "Heart",
								    "HeartO", "History", "Home", "HospitalO", "Html5", "Ils", "Image", "Inbox", "Indent", "Info", "InfoCircle",
								    "Inr", "Instagram", "Institution", "Ioxhost", "Italic", "Joomla", "Jpy", "Jsfiddle", "Key", "KeyboardO",
								    "Krw", "Language", "Laptop", "Lastfm", "LastfmSquare", "Leaf", "Legal", "LemonO", "LevelDown", "LevelUp",
								    "LifeBouy", "LifeBuoy", "LifeRing", "LifeSaver", "LightbulbO", "LineChart", "Link", "Linkedin",
								    "LinkedinSquare", "Linux", "List", "ListAlt", "ListOl", "ListUl", "LocationArrow", "Lock", 
								    "LongArrowDown", "LongArrowLeft", "LongArrowRight", "LongArrowUp", "Magic", "Magnet", "MailForward",
								    "MailReply", "MailReplyAll", "Male", "MapMarker", "Maxcdn", "Meanpath", "Medkit", "MehO", "Microphone",
								    "MicrophoneSlash", "Minus", "MinusCircle", "MinusSquare", "MinusSquareO", "Mobile", "MobilePhone", "Money",
								    "MoonO", "MortarBoard", "Music", "Navicon", "NewspaperO", "Openid", "Outdent", "Pagelines", "PaintBrush",
								    "PaperPlane", "PaperPlaneO", "Paperclip", "Paragraph", "Paste", "Pause", "Paw", "Paypal", "Pencil",
								    "PencilSquare", "PencilSquareO", "Phone", "PhoneSquare", "Photo", "PictureO", "PieChart", "PiedPiper",
								    "PiedPiperAlt", "Pinterest", "PinterestSquare", "Plane", "Play", "PlayCircle", "PlayCircleO", "Plug",
								    "Plus", "PlusCircle", "PlusSquare", "PlusSquareO", "PowerOff", "Print", "PuzzlePiece", "Qq", "Qrcode",
								    "Question", "QuestionCircle", "QuoteLeft", "QuoteRight", "Ra", "Random", "Rebel", "Recycle", "Reddit",
								    "RedditSquare", "Refresh", "Remove", "Renren", "Reorder", "Repeat", "Reply", "ReplyAll", "Retweet",
								    "Rmb", "Road", "Rocket", "RotateLeft", "RotateRight", "Rouble", "Rss", "RssSquare", "Rub", "Ruble",
								    "Rupee", "Save", "Scissors", "Search", "SearchMinus", "SearchPlus", "Send", "SendO", "Share", "ShareAlt",
								    "ShareAltSquare", "ShareSquare", "ShareSquareO", "Shekel", "Sheqel", "Shield", "ShoppingCart", "SignIn",
								    "SignOut", "Signal", "Sitemap", "Skype", "Slack", "Sliders", "Slideshare", "SmileO", "SoccerBallO",
								    "Sort", "SortAlphaAsc", "SortAlphaDesc", "SortAmountAsc", "SortAmountDesc", "SortAsc", "SortDesc",
								    "SortDown", "SortNumericAsc", "SortNumericDesc", "SortUp", "Soundcloud", "SpaceShuttle", "Spinner",
								    "Spoon", "Spotify", "Square", "SquareO", "StackExchange", "StackOverflow", "Star", "StarHalf", "StarHalfEmpty",
								    "StarHalfFull", "StarHalfO", "StarO", "Steam", "SteamSquare", "StepBackward", "StepForward", "Stethoscope",
								    "Stop", "Strikethrough", "Stumbleupon", "StumbleuponCircle", "Subscript", "Suitcase", "SunO", "Superscript",
								    "Support", "Table", "Tablet", "Tachometer", "Tag", "Tags", "Tasks", "Taxi", "TencentWeibo", "Terminal",
								    "TextHeight", "TextWidth", "Th", "ThLarge", "ThList", "ThumbTack", "ThumbsDown", "ThumbsODown", "ThumbsOUp",
								    "ThumbsUp", "Ticket", "Times", "TimesCircle", "TimesCircleO", "Tint", "ToggleDown", "ToggleLeft", "ToggleOff",
								    "ToggleOn", "ToggleRight", "ToggleUp", "Trash", "TrashO", "Tree", "Trello", "Trophy", "Truck", "Try", "Tty",
								    "Tumblr", "TumblrSquare", "TurkishLira", "Twitch", "Twitter", "TwitterSquare", "Umbrella", "Underline", "Undo",
								    "University", "Unlink", "Unlock", "UnlockAlt", "Unsorted", "Upload", "Usd", "User", "UserMd", "Users", "VideoCamera",
								    "VimeoSquare", "Vine", "Vk", "VolumeDown", "VolumeOff", "VolumeUp", "Warning", "Wechat", "Weibo", "Weixin", "Wheelchair",
								    "Wifi", "Windows", "Won", "Wordpress", "Wrench", "Xing", "XingSquare", "Yahoo", "Yelp", "Yen", "Youtube", "YoutubePlay",
								    "YoutubeSquare"
								    ];

enum Transparent          = Color { def toCSS = "transparent" }


alias NamedColor=Tuple(int,"r",int,"g",int,"b");


NamedColor[string] NamedColors=[		"AliceBlue": NamedColor(240, 248, 255),
										"AntiqueWhite": NamedColor(250, 235, 215),
										"Aqua": NamedColor( 0, 255, 255),
										"AquaMarine": NamedColor(127, 255, 212),
										"Azure": NamedColor(240, 255, 255),
										"Beige": NamedColor(245, 245, 220),
										"Bisque": NamedColor(255, 228, 196),
										"Black": NamedColor( 0, 0, 0),
										"BlanchedAlmond": NamedColor(255, 235, 205),
										"Blue": NamedColor( 0, 0, 255),
										"BlueViolet": NamedColor(138, 43, 226),
										"Brown": NamedColor(165, 42, 42),
										"BurlyWood": NamedColor(222, 184, 135),
										"CadetBlue": NamedColor( 95, 158, 160),
										"Chartreuse": NamedColor(127, 255, 0),
										"Chocolate": NamedColor(210, 105, 30),
										"Coral": NamedColor(255, 127, 80),
										"CornFlowerBlue": NamedColor(100, 149, 237),
										"Cornsilk": NamedColor(255, 248, 220),
										"Crimson": NamedColor(220, 20, 60),
										"Cyan": NamedColor( 0, 255, 255),
										"DarkBlue": NamedColor( 0, 0, 139),
										"DarkCyan": NamedColor( 0, 139, 139),
										"DarkGoldenRod": NamedColor(184, 134, 11),
										"DarkGray": NamedColor(169, 169, 169),
										"DarkGreen": NamedColor( 0, 100, 0),
										"DarkGrey": NamedColor(169, 169, 169),
										"DarkKhaki": NamedColor(189, 183, 107),
										"DarkMagenta": NamedColor(139, 0, 139),
										"DarkOliveGreen": NamedColor( 85, 107, 47),
										"DarkOrange": NamedColor(255, 140, 0),
										"DarkOrchid": NamedColor(153, 50, 204),
										"DarkRed": NamedColor(139, 0, 0),
										"DarkSalmon": NamedColor(233, 150, 122),
										"DarkSeaGreen": NamedColor(143, 188, 143),
										"DarkSlateBlue": NamedColor( 72, 61, 139),
										"DarkSlateGray": NamedColor( 47, 79, 79),
										"DarkSlateGrey": NamedColor( 47, 79, 79),
										"DarkTurquoise": NamedColor( 0, 206, 209),
										"DarkViolet": NamedColor(148, 0, 211),
										"DeepPink": NamedColor(255, 20, 147),
										"DeepSkyBlue": NamedColor( 0, 191, 255),
										"DimGray": NamedColor(105, 105, 105),
										"DimGrey": NamedColor(105, 105, 105),
										"DodgerBlue": NamedColor( 30, 144, 255),
										"FireBrick": NamedColor(178, 34, 34),
										"FloralWhite": NamedColor(255, 250, 240),
										"ForestGreen": NamedColor( 34, 139, 34),
										"Fuchsia": NamedColor(255, 0, 255),
										"Gainsboro": NamedColor(220, 220, 220),
										"GhostWhite": NamedColor(248, 248, 255),
										"Gold": NamedColor(255, 215, 0),
										"GoldenRod": NamedColor(218, 165, 32),
										"Gray": NamedColor(128, 128, 128),
										"Green": NamedColor( 0, 128, 0),
										"GreenYellow": NamedColor(173, 255, 47),
										"Grey": NamedColor(128, 128, 128),
										"HoneyDew": NamedColor(240, 255, 240),
										"HotPink": NamedColor(255, 105, 180),
										"IndianRed": NamedColor(205, 92, 92),
										"Indigo": NamedColor( 75, 0, 130),
										"Ivory": NamedColor(255, 255, 240),
										"Khaki": NamedColor(240, 230, 140),
										"Lavender": NamedColor(230, 230, 250),
										"LavenderBlush": NamedColor(255, 240, 245),
										"LawnGreen": NamedColor(124, 252, 0),
										"LemonChiffon": NamedColor(255, 250, 205),
										"LightBlue": NamedColor(173, 216, 230),
										"LightCoral": NamedColor(240, 128, 128),
										"LightCyan": NamedColor(224, 255, 255),
										"LightGoldenRodYellow": NamedColor(250, 250, 210),
										"LightGray": NamedColor(211, 211, 211),
										"LightGreen": NamedColor(144, 238, 144),
										"LightGrey": NamedColor(211, 211, 211),
										"LightPink": NamedColor(255, 182, 193),
										"LightSalmon": NamedColor(255, 160, 122),
										"LightSeaGreen": NamedColor( 32, 178, 170),
										"LightSkyBlue": NamedColor(135, 206, 250),
										"LightSlateGray": NamedColor(119, 136, 153),
										"LightSlateGrey": NamedColor(119, 136, 153),
										"LightSteelBlue": NamedColor(176, 196, 222),
										"LightYellow": NamedColor(255, 255, 224),
										"Lime": NamedColor( 0, 255, 0),
										"LimeGreen": NamedColor( 50, 205, 50),
										"Linen": NamedColor(250, 240, 230),
										"Magenta": NamedColor(255, 0, 255),
										"Maroon": NamedColor(128, 0, 0),
										"MediumAquaMarine": NamedColor(102, 205, 170),
										"MediumBlue": NamedColor( 0, 0, 205),
										"MediumOrchid": NamedColor(186, 85, 211),
										"MediumPurple": NamedColor(147, 112, 219),
										"MediumSeaGreen": NamedColor( 60, 179, 113),
										"MediumSlateBlue": NamedColor(123, 104, 238),
										"MediumSpringGreen": NamedColor( 0, 250, 154),
										"MediumTurquoise": NamedColor( 72, 209, 204),
										"MediumVioletRed": NamedColor(199, 21, 133),
										"MidnightBlue": NamedColor( 25, 25, 112),
										"MintCream": NamedColor(245, 255, 250),
										"MistyRose": NamedColor(255, 228, 225),
										"Moccasin": NamedColor(255, 228, 181),
										"NavajoWhite": NamedColor(255, 222, 173),
										"Navy": NamedColor( 0, 0, 128),
										"OldLace": NamedColor(253, 245, 230),
										"Olive": NamedColor(128, 128, 0),
										"OliveDrab": NamedColor(107, 142, 35),
										"Orange": NamedColor(255, 165, 0),
										"OrangeRed": NamedColor(255, 69, 0),
										"Orchid": NamedColor(218, 112, 214),
										"PaleGoldenRod": NamedColor(238, 232, 170),
										"PaleGreen": NamedColor(152, 251, 152),
										"PaleTurquoise": NamedColor(175, 238, 238),
										"PaleVioletRed": NamedColor(219, 112, 147),
										"PapayaWhip": NamedColor(255, 239, 213),
										"PeachPuff": NamedColor(255, 218, 185),
										"Peru": NamedColor(205, 133, 63),
										"Pink": NamedColor(255, 192, 203),
										"Plum": NamedColor(221, 160, 221),
										"PowderBlue": NamedColor(176, 224, 230),
										"Purple": NamedColor(128, 0, 128),
										"Red": NamedColor(255, 0, 0),
										"RosyBrown": NamedColor(188, 143, 143),
										"RoyalBlue": NamedColor( 65, 105, 225),
										"SaddleBrown": NamedColor(139, 69, 19),
										"Salmon": NamedColor(250, 128, 114),
										"SandyBrown": NamedColor(244, 164, 96),
										"SeaGreen": NamedColor( 46, 139, 87),
										"Seashell": NamedColor(255, 245, 238),
										"Sienna": NamedColor(160, 82, 45),
										"Silver": NamedColor(192, 192, 192),
										"SkyBlue": NamedColor(135, 206, 235),
										"SlateBlue": NamedColor(106, 90, 205),
										"SlateGray": NamedColor(112, 128, 144),
										"SlateGrey": NamedColor(112, 128, 144),
										"Snow": NamedColor(255, 250, 250),
										"SpringGreen": NamedColor( 0, 255, 127),
										"SteelBlue": NamedColor( 70, 130, 180),
										"Tan": NamedColor(210, 180, 140),
										"Teal": NamedColor( 0, 128, 128),
										"Thistle": NamedColor(216, 191, 216),
										"Tomato": NamedColor(255, 99, 71),
										"Turquoise": NamedColor( 64, 224, 208),
										"Violet": NamedColor(238, 130, 238),
										"Wheat": NamedColor(245, 222, 179),
										"White": NamedColor(255, 255, 255),
										"WhiteSmoke": NamedColor(245, 245, 245),
										"Yellow": NamedColor(255, 255, 0),
										"YellowGreen": NamedColor(154, 205, 50)
								];


NamedColor ParseColor(string color)
{
	enum RegexHexColor = ctRegex(r"""^#([\da-fA-F]{2})([\da-fA-F]{2})([\da-fA-F]{2})$""");
	enum RegexRGBColor = ctRefex(r"""^rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$""");
	auto c=color in NamedColors;
	if (c)
		return c;
	auto results=matchFirst(color,RegexHexColor);
	if (results.length==4)
		return NamedColor(results.hit[1].to!int,results.hit[2].to!int,results.hit[3].to!int);
	results=matchFirst(color,RegexRGBColor);
	if (results.length==4)
		return NamedColor(results.hit[1].to!int(16),results.hit[2].to!int(16),results.hit[3].to!int(16));
	throw new Exception("ParseColor: unknown color - "~color);
}

immutable string[string] Palette=
    [

        "YlGn3":      ["#31a354", "#addd8e", "#f7fcb9"],
        "YlGn4":      ["#238443", "#78c679", "#c2e699", "#ffffcc"],
        "YlGn5":      ["#006837", "#31a354", "#78c679", "#c2e699", "#ffffcc"],
        "YlGn6":      ["#006837", "#31a354", "#78c679", "#addd8e", "#d9f0a3", "#ffffcc"],
        "YlGn7":      ["#005a32", "#238443", "#41ab5d", "#78c679", "#addd8e", "#d9f0a3", "#ffffcc"],
        "YlGn8":      ["#005a32", "#238443", "#41ab5d", "#78c679", "#addd8e", "#d9f0a3", "#f7fcb9", "#ffffe5"],
        "YlGn9":      ["#004529", "#006837", "#238443", "#41ab5d", "#78c679", "#addd8e", "#d9f0a3", "#f7fcb9", "#ffffe5"],

        "YlGnBu3":    ["#2c7fb8", "#7fcdbb", "#edf8b1"],
        "YlGnBu4":    ["#225ea8", "#41b6c4", "#a1dab4", "#ffffcc"],
        "YlGnBu5":    ["#253494", "#2c7fb8", "#41b6c4", "#a1dab4", "#ffffcc"],
        "YlGnBu6":    ["#253494", "#2c7fb8", "#41b6c4", "#7fcdbb", "#c7e9b4", "#ffffcc"],
        "YlGnBu7":    ["#0c2c84", "#225ea8", "#1d91c0", "#41b6c4", "#7fcdbb", "#c7e9b4", "#ffffcc"],
        "YlGnBu8":    ["#0c2c84", "#225ea8", "#1d91c0", "#41b6c4", "#7fcdbb", "#c7e9b4", "#edf8b1", "#ffffd9"],
        "YlGnBu9":    ["#081d58", "#253494", "#225ea8", "#1d91c0", "#41b6c4", "#7fcdbb", "#c7e9b4", "#edf8b1", "#ffffd9"],

        "GnBu3":      ["#43a2ca", "#a8ddb5", "#e0f3db"],
        "GnBu4":      ["#2b8cbe", "#7bccc4", "#bae4bc", "#f0f9e8"],
        "GnBu5":      ["#0868ac", "#43a2ca", "#7bccc4", "#bae4bc", "#f0f9e8"],
        "GnBu6":      ["#0868ac", "#43a2ca", "#7bccc4", "#a8ddb5", "#ccebc5", "#f0f9e8"],
        "GnBu7":      ["#08589e", "#2b8cbe", "#4eb3d3", "#7bccc4", "#a8ddb5", "#ccebc5", "#f0f9e8"],
        "GnBu8":      ["#08589e", "#2b8cbe", "#4eb3d3", "#7bccc4", "#a8ddb5", "#ccebc5", "#e0f3db", "#f7fcf0"],
        "GnBu9":      ["#084081", "#0868ac", "#2b8cbe", "#4eb3d3", "#7bccc4", "#a8ddb5", "#ccebc5", "#e0f3db", "#f7fcf0"],

        "BuGn3":      ["#2ca25f", "#99d8c9", "#e5f5f9"],
        "BuGn4":      ["#238b45", "#66c2a4", "#b2e2e2", "#edf8fb"],
        "BuGn5":      ["#006d2c", "#2ca25f", "#66c2a4", "#b2e2e2", "#edf8fb"],
        "BuGn6":      ["#006d2c", "#2ca25f", "#66c2a4", "#99d8c9", "#ccece6", "#edf8fb"],
        "BuGn7":      ["#005824", "#238b45", "#41ae76", "#66c2a4", "#99d8c9", "#ccece6", "#edf8fb"],
        "BuGn8":      ["#005824", "#238b45", "#41ae76", "#66c2a4", "#99d8c9", "#ccece6", "#e5f5f9", "#f7fcfd"],
        "BuGn9":      ["#00441b", "#006d2c", "#238b45", "#41ae76", "#66c2a4", "#99d8c9", "#ccece6", "#e5f5f9", "#f7fcfd"],

        "PuBuGn3":    ["#1c9099", "#a6bddb", "#ece2f0"],
        "PuBuGn4":    ["#02818a", "#67a9cf", "#bdc9e1", "#f6eff7"],
        "PuBuGn5":    ["#016c59", "#1c9099", "#67a9cf", "#bdc9e1", "#f6eff7"],
        "PuBuGn6":    ["#016c59", "#1c9099", "#67a9cf", "#a6bddb", "#d0d1e6", "#f6eff7"],
        "PuBuGn7":    ["#016450", "#02818a", "#3690c0", "#67a9cf", "#a6bddb", "#d0d1e6", "#f6eff7"],
        "PuBuGn8":    ["#016450", "#02818a", "#3690c0", "#67a9cf", "#a6bddb", "#d0d1e6", "#ece2f0", "#fff7fb"],
        "PuBuGn9":    ["#014636", "#016c59", "#02818a", "#3690c0", "#67a9cf", "#a6bddb", "#d0d1e6", "#ece2f0", "#fff7fb"],

        "PuBu3":      ["#2b8cbe", "#a6bddb", "#ece7f2"],
        "PuBu4":      ["#0570b0", "#74a9cf", "#bdc9e1", "#f1eef6"],
        "PuBu5":      ["#045a8d", "#2b8cbe", "#74a9cf", "#bdc9e1", "#f1eef6"],
        "PuBu6":      ["#045a8d", "#2b8cbe", "#74a9cf", "#a6bddb", "#d0d1e6", "#f1eef6"],
        "PuBu7":      ["#034e7b", "#0570b0", "#3690c0", "#74a9cf", "#a6bddb", "#d0d1e6", "#f1eef6"],
        "PuBu8":      ["#034e7b", "#0570b0", "#3690c0", "#74a9cf", "#a6bddb", "#d0d1e6", "#ece7f2", "#fff7fb"],
        "PuBu9":      ["#023858", "#045a8d", "#0570b0", "#3690c0", "#74a9cf", "#a6bddb", "#d0d1e6", "#ece7f2", "#fff7fb"],

        "BuPu3":      ["#8856a7", "#9ebcda", "#e0ecf4"],
        "BuPu4":      ["#88419d", "#8c96c6", "#b3cde3", "#edf8fb"],
        "BuPu5":      ["#810f7c", "#8856a7", "#8c96c6", "#b3cde3", "#edf8fb"],
        "BuPu6":      ["#810f7c", "#8856a7", "#8c96c6", "#9ebcda", "#bfd3e6", "#edf8fb"],
        "BuPu7":      ["#6e016b", "#88419d", "#8c6bb1", "#8c96c6", "#9ebcda", "#bfd3e6", "#edf8fb"],
        "BuPu8":      ["#6e016b", "#88419d", "#8c6bb1", "#8c96c6", "#9ebcda", "#bfd3e6", "#e0ecf4", "#f7fcfd"],
        "BuPu9":      ["#4d004b", "#810f7c", "#88419d", "#8c6bb1", "#8c96c6", "#9ebcda", "#bfd3e6", "#e0ecf4", "#f7fcfd"],

        "RdPu3":      ["#c51b8a", "#fa9fb5", "#fde0dd"],
        "RdPu4":      ["#ae017e", "#f768a1", "#fbb4b9", "#feebe2"],
        "RdPu5":      ["#7a0177", "#c51b8a", "#f768a1", "#fbb4b9", "#feebe2"],
        "RdPu6":      ["#7a0177", "#c51b8a", "#f768a1", "#fa9fb5", "#fcc5c0", "#feebe2"],
        "RdPu7":      ["#7a0177", "#ae017e", "#dd3497", "#f768a1", "#fa9fb5", "#fcc5c0", "#feebe2"],
        "RdPu8":      ["#7a0177", "#ae017e", "#dd3497", "#f768a1", "#fa9fb5", "#fcc5c0", "#fde0dd", "#fff7f3"],
        "RdPu9":      ["#49006a", "#7a0177", "#ae017e", "#dd3497", "#f768a1", "#fa9fb5", "#fcc5c0", "#fde0dd", "#fff7f3"],

        "PuRd3":      ["#dd1c77", "#c994c7", "#e7e1ef"],
        "PuRd4":      ["#ce1256", "#df65b0", "#d7b5d8", "#f1eef6"],
        "PuRd5":      ["#980043", "#dd1c77", "#df65b0", "#d7b5d8", "#f1eef6"],
        "PuRd6":      ["#980043", "#dd1c77", "#df65b0", "#c994c7", "#d4b9da", "#f1eef6"],
        "PuRd7":      ["#91003f", "#ce1256", "#e7298a", "#df65b0", "#c994c7", "#d4b9da", "#f1eef6"],
        "PuRd8":      ["#91003f", "#ce1256", "#e7298a", "#df65b0", "#c994c7", "#d4b9da", "#e7e1ef", "#f7f4f9"],
        "PuRd9":      ["#67001f", "#980043", "#ce1256", "#e7298a", "#df65b0", "#c994c7", "#d4b9da", "#e7e1ef", "#f7f4f9"],

        "OrRd3":      ["#e34a33", "#fdbb84", "#fee8c8"],
        "OrRd4":      ["#d7301f", "#fc8d59", "#fdcc8a", "#fef0d9"],
        "OrRd5":      ["#b30000", "#e34a33", "#fc8d59", "#fdcc8a", "#fef0d9"],
        "OrRd6":      ["#b30000", "#e34a33", "#fc8d59", "#fdbb84", "#fdd49e", "#fef0d9"],
        "OrRd7":      ["#990000", "#d7301f", "#ef6548", "#fc8d59", "#fdbb84", "#fdd49e", "#fef0d9"],
        "OrRd8":      ["#990000", "#d7301f", "#ef6548", "#fc8d59", "#fdbb84", "#fdd49e", "#fee8c8", "#fff7ec"],
        "OrRd9":      ["#7f0000", "#b30000", "#d7301f", "#ef6548", "#fc8d59", "#fdbb84", "#fdd49e", "#fee8c8", "#fff7ec"],

        "YlOrRd3":    ["#f03b20", "#feb24c", "#ffeda0"],
        "YlOrRd4":    ["#e31a1c", "#fd8d3c", "#fecc5c", "#ffffb2"],
        "YlOrRd5":    ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#ffffb2"],
        "YlOrRd6":    ["#bd0026", "#f03b20", "#fd8d3c", "#feb24c", "#fed976", "#ffffb2"],
        "YlOrRd7":    ["#b10026", "#e31a1c", "#fc4e2a", "#fd8d3c", "#feb24c", "#fed976", "#ffffb2"],
        "YlOrRd8":    ["#b10026", "#e31a1c", "#fc4e2a", "#fd8d3c", "#feb24c", "#fed976", "#ffeda0", "#ffffcc"],
        "YlOrRd9":    ["#800026", "#bd0026", "#e31a1c", "#fc4e2a", "#fd8d3c", "#feb24c", "#fed976", "#ffeda0", "#ffffcc"],

        "YlOrBr3":    ["#d95f0e", "#fec44f", "#fff7bc"],
        "YlOrBr4":    ["#cc4c02", "#fe9929", "#fed98e", "#ffffd4"],
        "YlOrBr5":    ["#993404", "#d95f0e", "#fe9929", "#fed98e", "#ffffd4"],
        "YlOrBr6":    ["#993404", "#d95f0e", "#fe9929", "#fec44f", "#fee391", "#ffffd4"],
        "YlOrBr7":    ["#8c2d04", "#cc4c02", "#ec7014", "#fe9929", "#fec44f", "#fee391", "#ffffd4"],
        "YlOrBr8":    ["#8c2d04", "#cc4c02", "#ec7014", "#fe9929", "#fec44f", "#fee391", "#fff7bc", "#ffffe5"],
        "YlOrBr9":    ["#662506", "#993404", "#cc4c02", "#ec7014", "#fe9929", "#fec44f", "#fee391", "#fff7bc", "#ffffe5"],

        "Purples3":   ["#756bb1", "#bcbddc", "#efedf5"],
        "Purples4":   ["#6a51a3", "#9e9ac8", "#cbc9e2", "#f2f0f7"],
        "Purples5":   ["#54278f", "#756bb1", "#9e9ac8", "#cbc9e2", "#f2f0f7"],
        "Purples6":   ["#54278f", "#756bb1", "#9e9ac8", "#bcbddc", "#dadaeb", "#f2f0f7"],
        "Purples7":   ["#4a1486", "#6a51a3", "#807dba", "#9e9ac8", "#bcbddc", "#dadaeb", "#f2f0f7"],
        "Purples8":   ["#4a1486", "#6a51a3", "#807dba", "#9e9ac8", "#bcbddc", "#dadaeb", "#efedf5", "#fcfbfd"],
        "Purples9":   ["#3f007d", "#54278f", "#6a51a3", "#807dba", "#9e9ac8", "#bcbddc", "#dadaeb", "#efedf5", "#fcfbfd"],

        "Blues3":     ["#3182bd", "#9ecae1", "#deebf7"],
        "Blues4":     ["#2171b5", "#6baed6", "#bdd7e7", "#eff3ff"],
        "Blues5":     ["#08519c", "#3182bd", "#6baed6", "#bdd7e7", "#eff3ff"],
        "Blues6":     ["#08519c", "#3182bd", "#6baed6", "#9ecae1", "#c6dbef", "#eff3ff"],
        "Blues7":     ["#084594", "#2171b5", "#4292c6", "#6baed6", "#9ecae1", "#c6dbef", "#eff3ff"],
        "Blues8":     ["#084594", "#2171b5", "#4292c6", "#6baed6", "#9ecae1", "#c6dbef", "#deebf7", "#f7fbff"],
        "Blues9":     ["#08306b", "#08519c", "#2171b5", "#4292c6", "#6baed6", "#9ecae1", "#c6dbef", "#deebf7", "#f7fbff"],

        "Greens3":    ["#31a354", "#a1d99b", "#e5f5e0"],
        "Greens4":    ["#238b45", "#74c476", "#bae4b3", "#edf8e9"],
        "Greens5":    ["#006d2c", "#31a354", "#74c476", "#bae4b3", "#edf8e9"],
        "Greens6":    ["#006d2c", "#31a354", "#74c476", "#a1d99b", "#c7e9c0", "#edf8e9"],
        "Greens7":    ["#005a32", "#238b45", "#41ab5d", "#74c476", "#a1d99b", "#c7e9c0", "#edf8e9"],
        "Greens8":    ["#005a32", "#238b45", "#41ab5d", "#74c476", "#a1d99b", "#c7e9c0", "#e5f5e0", "#f7fcf5"],
        "Greens9":    ["#00441b", "#006d2c", "#238b45", "#41ab5d", "#74c476", "#a1d99b", "#c7e9c0", "#e5f5e0", "#f7fcf5"],

        "Oranges3":   ["#e6550d", "#fdae6b", "#fee6ce"],
        "Oranges4":   ["#d94701", "#fd8d3c", "#fdbe85", "#feedde"],
        "Oranges5":   ["#a63603", "#e6550d", "#fd8d3c", "#fdbe85", "#feedde"],
        "Oranges6":   ["#a63603", "#e6550d", "#fd8d3c", "#fdae6b", "#fdd0a2", "#feedde"],
        "Oranges7":   ["#8c2d04", "#d94801", "#f16913", "#fd8d3c", "#fdae6b", "#fdd0a2", "#feedde"],
        "Oranges8":   ["#8c2d04", "#d94801", "#f16913", "#fd8d3c", "#fdae6b", "#fdd0a2", "#fee6ce", "#fff5eb"],
        "Oranges9":   ["#7f2704", "#a63603", "#d94801", "#f16913", "#fd8d3c", "#fdae6b", "#fdd0a2", "#fee6ce", "#fff5eb"],

        "Reds3":      ["#de2d26", "#fc9272", "#fee0d2"],
        "Reds4":      ["#cb181d", "#fb6a4a", "#fcae91", "#fee5d9"],
        "Reds5":      ["#a50f15", "#de2d26", "#fb6a4a", "#fcae91", "#fee5d9"],
        "Reds6":      ["#a50f15", "#de2d26", "#fb6a4a", "#fc9272", "#fcbba1", "#fee5d9"],
        "Reds7":      ["#99000d", "#cb181d", "#ef3b2c", "#fb6a4a", "#fc9272", "#fcbba1", "#fee5d9"],
        "Reds8":      ["#99000d", "#cb181d", "#ef3b2c", "#fb6a4a", "#fc9272", "#fcbba1", "#fee0d2", "#fff5f0"],
        "Reds9":      ["#67000d", "#a50f15", "#cb181d", "#ef3b2c", "#fb6a4a", "#fc9272", "#fcbba1", "#fee0d2", "#fff5f0"],

        "Greys3":     ["#636363", "#bdbdbd", "#f0f0f0"],
        "Greys4":     ["#525252", "#969696", "#cccccc", "#f7f7f7"],
        "Greys5":     ["#252525", "#636363", "#969696", "#cccccc", "#f7f7f7"],
        "Greys6":     ["#252525", "#636363", "#969696", "#bdbdbd", "#d9d9d9", "#f7f7f7"],
        "Greys7":     ["#252525", "#525252", "#737373", "#969696", "#bdbdbd", "#d9d9d9", "#f7f7f7"],
        "Greys8":     ["#252525", "#525252", "#737373", "#969696", "#bdbdbd", "#d9d9d9", "#f0f0f0", "#ffffff"],
        "Greys9":     ["#000000", "#252525", "#525252", "#737373", "#969696", "#bdbdbd", "#d9d9d9", "#f0f0f0", "#ffffff"],

        "PuOr3":      ["#998ec3", "#f7f7f7", "#f1a340"],
        "PuOr4":      ["#5e3c99", "#b2abd2", "#fdb863", "#e66101"],
        "PuOr5":      ["#5e3c99", "#b2abd2", "#f7f7f7", "#fdb863", "#e66101"],
        "PuOr6":      ["#542788", "#998ec3", "#d8daeb", "#fee0b6", "#f1a340", "#b35806"],
        "PuOr7":      ["#542788", "#998ec3", "#d8daeb", "#f7f7f7", "#fee0b6", "#f1a340", "#b35806"],
        "PuOr8":      ["#542788", "#8073ac", "#b2abd2", "#d8daeb", "#fee0b6", "#fdb863", "#e08214", "#b35806"],
        "PuOr9":      ["#542788", "#8073ac", "#b2abd2", "#d8daeb", "#f7f7f7", "#fee0b6", "#fdb863", "#e08214", "#b35806"],
        "PuOr10":     ["#2d004b", "#542788", "#8073ac", "#b2abd2", "#d8daeb", "#fee0b6", "#fdb863", "#e08214", "#b35806", "#7f3b08"],
        "PuOr11":     ["#2d004b", "#542788", "#8073ac", "#b2abd2", "#d8daeb", "#f7f7f7", "#fee0b6", "#fdb863", "#e08214", "#b35806", "#7f3b08"],

        "BrBG3":      ["#5ab4ac", "#f5f5f5", "#d8b365"],
        "BrBG4":      ["#018571", "#80cdc1", "#dfc27d", "#a6611a"],
        "BrBG5":      ["#018571", "#80cdc1", "#f5f5f5", "#dfc27d", "#a6611a"],
        "BrBG6":      ["#01665e", "#5ab4ac", "#c7eae5", "#f6e8c3", "#d8b365", "#8c510a"],
        "BrBG7":      ["#01665e", "#5ab4ac", "#c7eae5", "#f5f5f5", "#f6e8c3", "#d8b365", "#8c510a"],
        "BrBG8":      ["#01665e", "#35978f", "#80cdc1", "#c7eae5", "#f6e8c3", "#dfc27d", "#bf812d", "#8c510a"],
        "BrBG9":      ["#01665e", "#35978f", "#80cdc1", "#c7eae5", "#f5f5f5", "#f6e8c3", "#dfc27d", "#bf812d", "#8c510a"],
        "BrBG10":     ["#003c30", "#01665e", "#35978f", "#80cdc1", "#c7eae5", "#f6e8c3", "#dfc27d", "#bf812d", "#8c510a", "#543005"],
        "BrBG11":     ["#003c30", "#01665e", "#35978f", "#80cdc1", "#c7eae5", "#f5f5f5", "#f6e8c3", "#dfc27d", "#bf812d", "#8c510a", "#543005"],

        "PRGn3":      ["#7fbf7b", "#f7f7f7", "#af8dc3"],
        "PRGn4":      ["#008837", "#a6dba0", "#c2a5cf", "#7b3294"],
        "PRGn5":      ["#008837", "#a6dba0", "#f7f7f7", "#c2a5cf", "#7b3294"],
        "PRGn6":      ["#1b7837", "#7fbf7b", "#d9f0d3", "#e7d4e8", "#af8dc3", "#762a83"],
        "PRGn7":      ["#1b7837", "#7fbf7b", "#d9f0d3", "#f7f7f7", "#e7d4e8", "#af8dc3", "#762a83"],
        "PRGn8":      ["#1b7837", "#5aae61", "#a6dba0", "#d9f0d3", "#e7d4e8", "#c2a5cf", "#9970ab", "#762a83"],
        "PRGn9":      ["#1b7837", "#5aae61", "#a6dba0", "#d9f0d3", "#f7f7f7", "#e7d4e8", "#c2a5cf", "#9970ab", "#762a83"],
        "PRGn10":     ["#00441b", "#1b7837", "#5aae61", "#a6dba0", "#d9f0d3", "#e7d4e8", "#c2a5cf", "#9970ab", "#762a83", "#40004b"],
        "PRGn11":     ["#00441b", "#1b7837", "#5aae61", "#a6dba0", "#d9f0d3", "#f7f7f7", "#e7d4e8", "#c2a5cf", "#9970ab", "#762a83", "#40004b"],

        "PiYG3":      ["#a1d76a", "#f7f7f7", "#e9a3c9"],
        "PiYG4":      ["#4dac26", "#b8e186", "#f1b6da", "#d01c8b"],
        "PiYG5":      ["#4dac26", "#b8e186", "#f7f7f7", "#f1b6da", "#d01c8b"],
        "PiYG6":      ["#4d9221", "#a1d76a", "#e6f5d0", "#fde0ef", "#e9a3c9", "#c51b7d"],
        "PiYG7":      ["#4d9221", "#a1d76a", "#e6f5d0", "#f7f7f7", "#fde0ef", "#e9a3c9", "#c51b7d"],
        "PiYG8":      ["#4d9221", "#7fbc41", "#b8e186", "#e6f5d0", "#fde0ef", "#f1b6da", "#de77ae", "#c51b7d"],
        "PiYG9":      ["#4d9221", "#7fbc41", "#b8e186", "#e6f5d0", "#f7f7f7", "#fde0ef", "#f1b6da", "#de77ae", "#c51b7d"],
        "PiYG10":     ["#276419", "#4d9221", "#7fbc41", "#b8e186", "#e6f5d0", "#fde0ef", "#f1b6da", "#de77ae", "#c51b7d", "#8e0152"],
        "PiYG11":     ["#276419", "#4d9221", "#7fbc41", "#b8e186", "#e6f5d0", "#f7f7f7", "#fde0ef", "#f1b6da", "#de77ae", "#c51b7d", "#8e0152"],

        "RdBu3":      ["#67a9cf", "#f7f7f7", "#ef8a62"],
        "RdBu4":      ["#0571b0", "#92c5de", "#f4a582", "#ca0020"],
        "RdBu5":      ["#0571b0", "#92c5de", "#f7f7f7", "#f4a582", "#ca0020"],
        "RdBu6":      ["#2166ac", "#67a9cf", "#d1e5f0", "#fddbc7", "#ef8a62", "#b2182b"],
        "RdBu7":      ["#2166ac", "#67a9cf", "#d1e5f0", "#f7f7f7", "#fddbc7", "#ef8a62", "#b2182b"],
        "RdBu8":      ["#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#fddbc7", "#f4a582", "#d6604d", "#b2182b"],
        "RdBu9":      ["#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#f7f7f7", "#fddbc7", "#f4a582", "#d6604d", "#b2182b"],
        "RdBu10":     ["#053061", "#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#fddbc7", "#f4a582", "#d6604d", "#b2182b", "#67001f"],
        "RdBu11":     ["#053061", "#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#f7f7f7", "#fddbc7", "#f4a582", "#d6604d", "#b2182b", "#67001f"],

        "RdGy3":      ["#999999", "#ffffff", "#ef8a62"],
        "RdGy4":      ["#404040", "#bababa", "#f4a582", "#ca0020"],
        "RdGy5":      ["#404040", "#bababa", "#ffffff", "#f4a582", "#ca0020"],
        "RdGy6":      ["#4d4d4d", "#999999", "#e0e0e0", "#fddbc7", "#ef8a62", "#b2182b"],
        "RdGy7":      ["#4d4d4d", "#999999", "#e0e0e0", "#ffffff", "#fddbc7", "#ef8a62", "#b2182b"],
        "RdGy8":      ["#4d4d4d", "#878787", "#bababa", "#e0e0e0", "#fddbc7", "#f4a582", "#d6604d", "#b2182b"],
        "RdGy9":      ["#4d4d4d", "#878787", "#bababa", "#e0e0e0", "#ffffff", "#fddbc7", "#f4a582", "#d6604d", "#b2182b"],
        "RdGy10":     ["#1a1a1a", "#4d4d4d", "#878787", "#bababa", "#e0e0e0", "#fddbc7", "#f4a582", "#d6604d", "#b2182b", "#67001f"],
        "RdGy11":     ["#1a1a1a", "#4d4d4d", "#878787", "#bababa", "#e0e0e0", "#ffffff", "#fddbc7", "#f4a582", "#d6604d", "#b2182b", "#67001f"],

        "RdYlBu3":    ["#91bfdb", "#ffffbf", "#fc8d59"],
        "RdYlBu4":    ["#2c7bb6", "#abd9e9", "#fdae61", "#d7191c"],
        "RdYlBu5":    ["#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"],
        "RdYlBu6":    ["#4575b4", "#91bfdb", "#e0f3f8", "#fee090", "#fc8d59", "#d73027"],
        "RdYlBu7":    ["#4575b4", "#91bfdb", "#e0f3f8", "#ffffbf", "#fee090", "#fc8d59", "#d73027"],
        "RdYlBu8":    ["#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#fee090", "#fdae61", "#f46d43", "#d73027"],
        "RdYlBu9":    ["#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#ffffbf", "#fee090", "#fdae61", "#f46d43", "#d73027"],
        "RdYlBu10":   ["#313695", "#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#fee090", "#fdae61", "#f46d43", "#d73027", "#a50026"],
        "RdYlBu11":   ["#313695", "#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#ffffbf", "#fee090", "#fdae61", "#f46d43", "#d73027", "#a50026"],

        "Spectral3":  ["#99d594", "#ffffbf", "#fc8d59"],
        "Spectral4":  ["#2b83ba", "#abdda4", "#fdae61", "#d7191c"],
        "Spectral5":  ["#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"],
        "Spectral6":  ["#3288bd", "#99d594", "#e6f598", "#fee08b", "#fc8d59", "#d53e4f"],
        "Spectral7":  ["#3288bd", "#99d594", "#e6f598", "#ffffbf", "#fee08b", "#fc8d59", "#d53e4f"],
        "Spectral8":  ["#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#fee08b", "#fdae61", "#f46d43", "#d53e4f"],
        "Spectral9":  ["#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#ffffbf", "#fee08b", "#fdae61", "#f46d43", "#d53e4f"],
        "Spectral10": ["#5e4fa2", "#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#fee08b", "#fdae61", "#f46d43", "#d53e4f", "#9e0142"],
        "Spectral11": ["#5e4fa2", "#3288bd", "#66c2a5", "#abdda4", "#e6f598", "#ffffbf", "#fee08b", "#fdae61", "#f46d43", "#d53e4f", "#9e0142"],

        "RdYlGn3":    ["#91cf60", "#ffffbf", "#fc8d59"],
        "RdYlGn4":    ["#1a9641", "#a6d96a", "#fdae61", "#d7191c"],
        "RdYlGn5":    ["#1a9641", "#a6d96a", "#ffffbf", "#fdae61", "#d7191c"],
        "RdYlGn6":    ["#1a9850", "#91cf60", "#d9ef8b", "#fee08b", "#fc8d59", "#d73027"],
        "RdYlGn7":    ["#1a9850", "#91cf60", "#d9ef8b", "#ffffbf", "#fee08b", "#fc8d59", "#d73027"],
        "RdYlGn8":    ["#1a9850", "#66bd63", "#a6d96a", "#d9ef8b", "#fee08b", "#fdae61", "#f46d43", "#d73027"],
        "RdYlGn9":    ["#1a9850", "#66bd63", "#a6d96a", "#d9ef8b", "#ffffbf", "#fee08b", "#fdae61", "#f46d43", "#d73027"],
        "RdYlGn10":   ["#006837", "#1a9850", "#66bd63", "#a6d96a", "#d9ef8b", "#fee08b", "#fdae61", "#f46d43", "#d73027", "#a50026"],
        "RdYlGn11":   ["#006837", "#1a9850", "#66bd63", "#a6d96a", "#d9ef8b", "#ffffbf", "#fee08b", "#fdae61", "#f46d43", "#d73027",
                        "#a50026"]
    ];

string[int][][string] brewer=
    [       "YlGn"     : [3 : "YlGn3",     4 : "YlGn4",     5 : "YlGn5",     6 : "YlGn6",     7 : "YlGn7",     8 : "YlGn8",     9 : "YlGn9"    ],
            "YlGnBu"   : [3 : "YlGnBu3",   4 : "YlGnBu4",   5 : "YlGnBu5",   6 : "YlGnBu6",   7 : "YlGnBu7",   8 : "YlGnBu8",   9 : "YlGnBu9"  ],
            "GnBu"     : [3 : "GnBu3",     4 : "GnBu4",     5 : "GnBu5",     6 : "GnBu6",     7 : "GnBu7",     8 : "GnBu8",     9 : "GnBu9"    ],
            "BuGn"     : [3 : "BuGn3",     4 : "BuGn4",     5 : "BuGn5",     6 : "BuGn6",     7 : "BuGn7",     8 : "BuGn8",     9 : "BuGn9"    ],
            "PuBuGn"   : [3 : "PuBuGn3",   4 : "PuBuGn4",   5 : "PuBuGn5",   6 : "PuBuGn6",   7 : "PuBuGn7",   8 : "PuBuGn8",   9 : "PuBuGn9"  ],
            "PuBu"     : [3 : "PuBu3",     4 : "PuBu4",     5 : "PuBu5",     6 : "PuBu6",     7 : "PuBu7",     8 : "PuBu8",     9 : "PuBu9"    ],
            "BuPu"     : [3 : "BuPu3",     4 : "BuPu4",     5 : "BuPu5",     6 : "BuPu6",     7 : "BuPu7",     8 : "BuPu8",     9 : "BuPu9"    ],
            "RdPu"     : [3 : "RdPu3",     4 : "RdPu4",     5 : "RdPu5",     6 : "RdPu6",     7 : "RdPu7",     8 : "RdPu8",     9 : "RdPu9"    ],
            "PuRd"     : [3 : "PuRd3",     4 : "PuRd4",     5 : "PuRd5",     6 : "PuRd6",     7 : "PuRd7",     8 : "PuRd8",     9 : "PuRd9"    ],
            "OrRd"     : [3 : "OrRd3",     4 : "OrRd4",     5 : "OrRd5",     6 : "OrRd6",     7 : "OrRd7",     8 : "OrRd8",     9 : "OrRd9"    ],
            "YlOrRd"   : [3 : "YlOrRd3",   4 : "YlOrRd4",   5 : "YlOrRd5",   6 : "YlOrRd6",   7 : "YlOrRd7",   8 : "YlOrRd8",   9 : "YlOrRd9"  ],
            "YlOrBr"   : [3 : "YlOrBr3",   4 : "YlOrBr4",   5 : "YlOrBr5",   6 : "YlOrBr6",   7 : "YlOrBr7",   8 : "YlOrBr8",   9 : "YlOrBr9"  ],
            "Purples"  : [3 : "Purples3",  4 : "Purples4",  5 : "Purples5",  6 : "Purples6",  7 : "Purples7",  8 : "Purples8",  9 : "Purples9" ],
            "Blues"    : [3 : "Blues3",    4 : "Blues4",    5 : "Blues5",    6 : "Blues6",    7 : "Blues7",    8 : "Blues8",    9 : "Blues9"   ],
            "Greens"   : [3 : "Greens3",   4 : "Greens4",   5 : "Greens5",   6 : "Greens6",   7 : "Greens7",   8 : "Greens8",   9 : "Greens9"  ],
            "Oranges"  : [3 : "Oranges3",  4 : "Oranges4",  5 : "Oranges5",  6 : "Oranges6",  7 : "Oranges7",  8 : "Oranges8",  9 : "Oranges9" ],
            "Reds"     : [3 : "Reds3",     4 : "Reds4",     5 : "Reds5",     6 : "Reds6",     7 : "Reds7",     8 : "Reds8",     9 : "Reds9"    ],
            "Greys"    : [3 : "Greys3",    4 : "Greys4",    5 : "Greys5",    6 : "Greys6",    7 : "Greys7",    8 : "Greys8",    9 : "Greys9"   ],
            "PuOr"     : [3 : "PuOr3",     4 : "PuOr4",     5 : "PuOr5",     6 : "PuOr6",     7 : "PuOr7",     8 : "PuOr8",     9 : "PuOr9",      10 : "PuOr10",     11 : "PuOr11"     ],
            "BrBG"     : [3 : "BrBG3",     4 : "BrBG4",     5 : "BrBG5",     6 : "BrBG6",     7 : "BrBG7",     8 : "BrBG8",     9 : "BrBG9",      10 : "BrBG10",     11 : "BrBG11"     ],
            "PRGn"     : [3 : "PRGn3",     4 : "PRGn4",     5 : "PRGn5",     6 : "PRGn6",     7 : "PRGn7",     8 : "PRGn8",     9 : "PRGn9",      10 : "PRGn10",     11 : "PRGn11"     ],
            "PiYG"     : [3 : "PiYG3",     4 : "PiYG4",     5 : "PiYG5",     6 : "PiYG6",     7 : "PiYG7",     8 : "PiYG8",     9 : "PiYG9",      10 : "PiYG10",     11 : "PiYG11"     ],
            "RdBu"     : [3 : "RdBu3",     4 : "RdBu4",     5 : "RdBu5",     6 : "RdBu6",     7 : "RdBu7",     8 : "RdBu8",     9 : "RdBu9",      10 : "RdBu10",     11 : "RdBu11"     ],
            "RdGy"     : [3 : "RdGy3",     4 : "RdGy4",     5 : "RdGy5",     6 : "RdGy6",     7 : "RdGy7",     8 : "RdGy8",     9 : "RdGy9",      10 : "RdGy10",     11 : "RdGy11"     ],
            "RdYlBu"   : [3 : "RdYlBu3",   4 : "RdYlBu4",   5 : "RdYlBu5",   6 : "RdYlBu6",   7 : "RdYlBu7",   8 : "RdYlBu8",   9 : "RdYlBu9",    10 : "RdYlBu10",   11 : "RdYlBu11"   ],
            "Spectral" : [3 : "Spectral3", 4 : "Spectral4", 5 : "Spectral5",  6 : "Spectral6",7 : "Spectral7", 8 : "Spectral8", 9 : "Spectral9",  10 : "Spectral10", 11 : "Spectral11" ],
            "RdYlGn"   : [3 : "RdYlGn3",   4 : "RdYlGn4",   5 : "RdYlGn5",   6 : "RdYlGn6",   7 : "RdYlGn7",   8 : "RdYlGn8",   9 : "RdYlGn9",    10 : "RdYlGn10",   11 : "RdYlGn11"   ],
    ];


/**
abstract class RGBAColor(red: Int, green: Int, blue: Int, alpha: Double) extends Color

case class RGBA(red: Int, green: Int, blue: Int, alpha: Double) extends RGBAColor(red, green, blue, alpha) {
    def toCSS = s"rgba($red, $green, $blue, $alpha)"
}

case class RGB(red: Int, green: Int, blue: Int) extends RGBAColor(red, green, blue, 1.0) {
    def toCSS = f"#$red%02x$green%02x$blue%02x" // XXX: s"rgb($red, $green, $blue)"?
}

abstract class HSLAColor(hue: Int, saturation: Percent, lightness: Percent, alpha: Double) extends Color

case class HSLA(hue: Int, saturation: Percent, lightness: Percent, alpha: Double) extends HSLAColor(hue, saturation, lightness, alpha) {
    def toCSS = s"hsla($hue, $saturation, $lightness, $alpha)"
}

case class HSL(hue: Int, saturation: Percent, lightness: Percent) extends HSLAColor(hue, saturation, lightness, 1.0) {
    def toCSS = s"hsl($hue, $saturation, $lightness)"
}

sealed abstract class NamedColor(red: Int, green: Int, blue: Int) extends RGBAColor(red, green, blue, 1.0) with EnumType with LowerCase {
    def toCSS = name
*/

immutable int[][string] DashPattern =	[	"Solid":	[],
											"Dashed":  [6],
											"Dotted"   [2, 4],
											"DotDash": [2, 4, 6, 4],
											"DashDot": [6, 4, 2, 4],
										];
