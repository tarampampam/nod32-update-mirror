package cli

import (
	"github.com/sirupsen/logrus"
	"nod32-update-mirror/internal/pkg/cli/flush"
	"nod32-update-mirror/internal/pkg/cli/key"
	"nod32-update-mirror/internal/pkg/cli/serve"
	"nod32-update-mirror/internal/pkg/cli/stat"
	"nod32-update-mirror/internal/pkg/cli/update"
	"nod32-update-mirror/internal/pkg/cli/version"

	"github.com/spf13/cobra"
)

// Application banner (generate own using <http://patorjk.com/software/taag/#p=display&f=Small&t=FooBar>)
const banner = `    _   __          __________      __  ____
   / | / /___  ____/ /__  /__ \    /  |/  (_)_____________  _____
  /  |/ / __ \/ __  / /_ <__/ /   / /|_/ / / ___/ ___/ __ \/ ___/
 / /|  / /_/ / /_/ /___/ / __/   / /  / / / /  / /  / /_/ / /
/_/ |_/\____/\__,_//____/____/  /_/  /_/_/_/  /_/   \____/_/`

// NewCommand creates `nod32-mirror` command.
func NewCommand(name string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   name,
		Short: "ESET Nod32 Updates Mirror",
		Long:  banner,
	}

	cmd.PersistentFlags().StringP("config", "c", "./configs/config.yaml", "Config file")
	cmd.PersistentFlags().BoolP("verbose", "v", false, "Verbose output")

	logger := newLogger()

	cmd.AddCommand(
		version.NewCommand(),
		update.NewCommand(),
		flush.NewCommand(),
		serve.NewCommand(logger),
		key.NewCommand(),
		stat.NewCommand(),
	)

	return cmd
}

func newLogger() *logrus.Logger {
	return logrus.New()
}
