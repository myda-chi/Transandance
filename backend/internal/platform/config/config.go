package config

import (
	"fmt"
	"os"
)


// config holds the settings every service needs to start.
type Config struct {
	ServiceName string
	Port		string
	DatabaseURL string
}


// Load settings from environment variables.
func Load(serviceName string) (Config, error) {
	cfg := Config{
		ServiceName: serviceName,
		Port:        os.Getenv("PORT"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
	}
	if cfg.Port == "" {
		return Config{}, fmt.Errorf("Port is not set")
	}
	if cfg.DatabaseURL == "" {
		return Config{}, fmt.Errorf("DATABASE_URL is not set")
	}
	return cfg, nil
}
