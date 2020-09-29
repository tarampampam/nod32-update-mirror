package version

import (
	"fmt"
	"nod32-update-mirror/internal/pkg/version"

	"github.com/spf13/cobra"
)

// NewCommand creates `version` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Show application version",
		Run: func(c *cobra.Command, args []string) {
			if _, err := fmt.Fprintf(c.OutOrStdout(), "Version: %s\n", version.Version()); err != nil {
				c.PrintErr(err)
			}
		},
	}
}
