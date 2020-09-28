package key

import (
	"nod32-update-mirror/internal/pkg/cmd/cli/key/get"
	"nod32-update-mirror/internal/pkg/cmd/cli/key/list"
	"nod32-update-mirror/internal/pkg/cmd/cli/key/update"

	"github.com/spf13/cobra"
)

// NewCommand creates `key` command.
func NewCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "key",
		Short: "Free license keys (USE FOR EDUCATIONAL OR INFORMATIONAL PURPOSES ONLY!)",
	}

	cmd.AddCommand(
		get.NewCommand(),
		list.NewCommand(),
		update.NewCommand(),
	)

	return cmd
}
