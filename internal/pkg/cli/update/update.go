package update

import (
	"fmt"
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/pkg/nod32mirror"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates `update` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "update",
		Short: "Update mirror",
		Run: func(c *cobra.Command, _ []string) {
			dl := nod32mirror.NewDownloader()

			fmt.Println(dl.CheckServer("http://um01.eset.com/eset_upd"))
		},
	}
}
