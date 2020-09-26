package version

// version value will be set during compilation
var version string = "undefined@undefined"

// Version return application version.
func Version() string {
	return version
}
