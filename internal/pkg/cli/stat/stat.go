package stat

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates `stat` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "stat",
		Short: "Show statistic information",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
