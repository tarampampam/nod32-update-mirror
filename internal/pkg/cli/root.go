package cli

import (
	"errors"
	"nod32-update-mirror/internal/pkg/cli/flush"
	"nod32-update-mirror/internal/pkg/cli/key"
	"nod32-update-mirror/internal/pkg/cli/serve"
	"nod32-update-mirror/internal/pkg/cli/stat"
	"nod32-update-mirror/internal/pkg/cli/update"
	"nod32-update-mirror/internal/pkg/cli/version"
	"nod32-update-mirror/internal/pkg/config"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// Application banner (generate own using <http://patorjk.com/software/taag/#p=display&f=Small&t=FooBar>)
const banner = `    _   __          __________      __  ____
   / | / /___  ____/ /__  /__ \    /  |/  (_)_____________  _____
  /  |/ / __ \/ __  / /_ <__/ /   / /|_/ / / ___/ ___/ __ \/ ___/
 / /|  / /_/ / /_/ /___/ / __/   / /  / / / /  / /  / /_/ / /
/_/ |_/\____/\__,_//____/____/  /_/  /_/_/_/  /_/   \____/_/`

const flagConfigName = "config"

// NewCommand creates `nod32-mirror` command.
func NewCommand(name string) *cobra.Command {
	var (
		cfg    *config.Config = &config.Config{}
		logger *logrus.Logger = newLogger()
	)

	cmd := &cobra.Command{
		Use:   name,
		Short: "ESET Nod32 Updates Mirror",
		Long:  banner,

		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			flagConfig := cmd.Flag(flagConfigName)
			if flagConfig == nil {
				return errors.New("config flag was not provided")
			}

			loadedCfg, err := config.FromYamlFile(flagConfig.Value.String(), true)
			if err != nil {
				return errors.New("config file: " + err.Error())
			}

			// change "global" config reference with loaded
			*cfg = *loadedCfg

			return nil
		},
	}

	cmd.PersistentFlags().String(flagConfigName, "./configs/config.yml", "Config file")
	cmd.PersistentFlags().BoolP("verbose", "v", false, "Verbose output")

	cmd.SilenceErrors = true
	cmd.SilenceUsage = true

	cmd.AddCommand(
		version.NewCommand(),
		update.NewCommand(logger, cfg),
		flush.NewCommand(logger, cfg),
		serve.NewCommand(logger, cfg),
		key.NewCommand(logger, cfg),
		stat.NewCommand(cfg),
	)

	return cmd
}

func newLogger() *logrus.Logger {
	return logrus.New()
}
