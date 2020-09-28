package get

import (
	"fmt"

	"github.com/spf13/cobra"
)

// NewCommand creates key `get` command.
func NewCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "get",
		Short: "Get one working key",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement
		},
	}
}
