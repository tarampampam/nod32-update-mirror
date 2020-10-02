package list

import (
	"errors"
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/fs"
	"nod32-update-mirror/pkg/keys/keepers"
	"sort"
	"strings"
	"time"

	"github.com/olekukonko/tablewriter"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates keys `list` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "Show all keys",
		RunE: func(c *cobra.Command, _ []string) error {
			if err := fs.MkdirAllForFile(cfg.Mirror.FreeKeys.FilePath, 0775); err != nil {
				return err
			}

			keeper := keepers.NewFileKeeper(cfg.Mirror.FreeKeys.FilePath)

			keys, err := keeper.All()
			if err != nil {
				return errors.New("cannot read keys from storage: " + err.Error())
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

			return nil
		},
	}
}
