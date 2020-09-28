package flush

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates `flush` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "flush",
		Short: "Remove all downloaded mirror files",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
