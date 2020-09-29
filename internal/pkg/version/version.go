package version

import "strings"

// version value will be set during compilation
var version string = "v0.0.0@undefined"

// Version return application version.
func Version() string {
	return strings.TrimLeft(version, " vV")
}
