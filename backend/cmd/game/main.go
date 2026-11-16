package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"github.com/myda-chi/Transandance/backend/internal/platform/config"
	"github.com/myda-chi/Transandance/backend/internal/platform/database"
	"github.com/myda-chi/Transandance/backend/internal/platform/health"
)

func main() {
	//1. Read setting (PORT, DATABASE_URL) from the environment.
	cfg, err := config.Load("game")
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	//2. Connect to the postgreSQL as this service's own database user.
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	//3. create the web server and the /health route.
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	health.Register(r, cfg.ServiceName, db)

	// 4. Start listening for requests (this line blocks while the service runs)
	log.Printf("%s service listening on :%s", cfg.ServiceName, cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
