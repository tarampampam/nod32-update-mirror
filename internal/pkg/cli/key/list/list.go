package list

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates key `list` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "Show all keys",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
