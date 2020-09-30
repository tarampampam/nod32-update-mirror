package list

import (
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/keys/keepers"
	"sort"
	"strings"
	"time"

	"github.com/olekukonko/tablewriter"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates key `list` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "Show all keys",
		Run: func(c *cobra.Command, args []string) {
			keeper := keepers.NewFileKeeper(cfg.Mirror.FreeKeys.FilePath)

			keys, err := keeper.All()
			if err != nil {
				l.WithError(err).Error("Cannot read keys from storage")

				return
			}

			if keys != nil && len(*keys) > 0 {
				table := tablewriter.NewWriter(c.OutOrStdout())
				table.SetHeader([]string{"ID", "Password", "Applicable for", "Expiring at", "Added at"})
				table.SetAutoWrapText(false)

				sort.Slice(*keys, func(i, j int) bool {
					return (*keys)[i].ExpiringAtUnix < (*keys)[j].ExpiringAtUnix
				})

				for _, k := range *keys {
					var (
						types               = make([]string, 0)
						addedAt, expiringAt = "", ""
					)

					for _, t := range k.Types {
						types = append(types, string(t))
					}

					if k.AddedAtUnix > 0 {
						addedAt = time.Unix(k.AddedAtUnix, 0).Format("2006-01-02 15:04:05")
					}

					if k.ExpiringAtUnix > 0 {
						expiringAt = time.Unix(k.ExpiringAtUnix, 0).Format("2006-01-02")
					}

					table.Append([]string{
						k.ID,
						k.Password,
						strings.Join(types, " "),
						expiringAt,
						addedAt,
					})
				}

				table.Render()
			} else {
				l.Warn("Keys storage is empty")
			}
		},
	}
}
