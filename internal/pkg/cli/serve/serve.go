package serve

import (
	"fmt"
	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates `serve` command.
func NewCommand(l *logrus.Logger) *cobra.Command {
	return &cobra.Command{
		Use:   "serve",
		Short: "Start HTTP server for mirrored files",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println("WIP") // TODO: Implement

			l.Info("foo bar")

			if f := c.Flag("config"); f != nil {
				fmt.Println(f.Value.String())
			}
		},
	}
}
