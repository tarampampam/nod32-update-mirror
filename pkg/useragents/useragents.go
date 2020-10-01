package useragents

const (
	firefoxUserAgent      = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:81.0) Gecko/20100101 Firefox/81.0"
	googleChromeUserAgent = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3880.4 Safari/537.36"                                                    //nolint:lll
	nodClientUserAgent    = "ESS Update (Windows; U; 32bit; VDB 10000; BPC 6.0.500.0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)" //nolint:lll
)

func Nod32Client() string {
	return nodClientUserAgent
}

func FireFox() string {
	return firefoxUserAgent
}

func GoogleChrome() string {
	return googleChromeUserAgent
}
