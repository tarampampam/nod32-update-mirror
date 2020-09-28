package update

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates `update` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "update",
		Short: "Update mirror",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
