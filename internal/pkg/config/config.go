package config

import (
	"io/ioutil"

	"github.com/a8m/envsubst"
	"gopkg.in/yaml.v2"
)

// Config is main configuration structure
type Config struct {
	Mirror      mirror      `yaml:"mirror"`
	Downloading downloading `yaml:"downloading"`
	HTTP        http        `yaml:"http"`
}

type (
	mirror struct {
		Path      string          `yaml:"path"`
		Servers   []mirrorServer  `yaml:"servers"`
		FreeKeys  mirrorFreeKeys  `yaml:"free-keys"`
		Filtering mirrorFiltering `yaml:"filtering"`
		Checking  mirrorChecking  `yaml:"checking"`
	}

	mirrorFreeKeys struct {
		Enabled  bool   `yaml:"enabled"`
		FilePath string `yaml:"file-path"`
	}

	mirrorServer struct {
		URL      string `yaml:"url"`
		Username string `yaml:"username"`
		Password string `yaml:"password"`
	}

	mirrorFiltering struct {
		Platforms []string `yaml:"platforms"`
		Types     []string `yaml:"types"`
		Languages []string `yaml:"languages"`
		Versions  []string `yaml:"versions"`
	}

	mirrorChecking struct {
		URL string `yaml:"url"`
	}
)

type (
	downloading struct {
		Threads    uint16 `yaml:"threads"`
		MaxSpeedKB uint32 `yaml:"max-speed-kb"`
	}
)

type (
	http struct {
		Listen    string        `yaml:"listen"`
		BasicAuth httpBasicAuth `yaml:"basic-auth"`
	}

	httpBasicAuth struct {
		Enabled bool                `yaml:"enabled"`
		Users   []httpBasicAuthUser `yaml:"users"`
	}

	httpBasicAuthUser struct {
		Username string `yaml:"username"`
		Password string `yaml:"password"`
	}
)

// FromYaml creates new config instance using YAML-structured content.
func FromYaml(in []byte, expandEnv bool) (*Config, error) {
	config := &Config{}

	if expandEnv {
		parsed, err := envsubst.Bytes(in)
		if err != nil {
			return nil, err
		}

		in = parsed
	}

	if err := yaml.UnmarshalStrict(in, config); err != nil {
		return nil, err
	}

	return config, nil
}

// FromYamlFile creates new config instance using YAML file.
func FromYamlFile(filename string, expandEnv bool) (*Config, error) {
	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	return FromYaml(bytes, expandEnv)
}
