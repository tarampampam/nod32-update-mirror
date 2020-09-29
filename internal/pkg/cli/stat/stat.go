package stat

import (
	"fmt"
	"nod32-update-mirror/internal/pkg/config"

	"github.com/spf13/cobra"
)

// NewCommand creates `stat` command.
func NewCommand(cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "stat",
		Short: "Show statistic information",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP ", cfg)
		},
	}
}
