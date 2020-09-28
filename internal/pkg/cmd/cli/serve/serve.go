package serve

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates `serve` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "serve",
		Short: "Start HTTP server for mirrored files serving",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
