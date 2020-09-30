package cli

import (
	"errors"
	"nod32-update-mirror/internal/pkg/cli/flush"
	"nod32-update-mirror/internal/pkg/cli/keys"
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
const flagVerboseName = "verbose"

// NewCommand creates `nod32-mirror` command.
func NewCommand(name string) *cobra.Command {
	var (
		cfg     *config.Config = &config.Config{}
		logger  *logrus.Logger = newLogger()
		verbose bool
	)

	cmd := &cobra.Command{
		Use:   name,
		Short: "ESET Nod32 Updates Mirror",
		Long:  banner,

		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			if verbose {
				logger.SetLevel(logrus.DebugLevel)
			}

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
	cmd.PersistentFlags().BoolVarP(&verbose, flagVerboseName, "v", false, "Verbose output")

	cmd.SilenceErrors = true
	cmd.SilenceUsage = true

	cmd.AddCommand(
		version.NewCommand(),
		update.NewCommand(logger, cfg),
		flush.NewCommand(logger, cfg),
		serve.NewCommand(logger, cfg),
		keys.NewCommand(logger, cfg),
		stat.NewCommand(cfg),
	)

	return cmd
}

func newLogger() *logrus.Logger {
	l := logrus.New()

	l.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:          true,
		TimestampFormat:        "2006-01-02 15:04:05.000",
		DisableLevelTruncation: true,
	})

	return l
}
