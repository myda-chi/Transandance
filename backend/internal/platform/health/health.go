package health

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type dbInfo struct {
	DBuser string `gorm:"column:db_user"`
	DBschema string `gorm:"column:db_schema"`
}

// Register add GET health/ to the router.
func Register(r *gin.Engine, service string, db *gorm.DB) {
	r.GET("/health", func(c *gin.Context) {
		var info dbInfo
		err :=db.WithContext(c.Request.Context()).
			Raw("Select current_user AS db_user, current_schema() AS db_schema").
			Scan(&info).Error
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "error", "service": service, "database": "down",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status": "ok", "service": service, "database": "up",
			"dbUser": info.DBuser, "dbSchema": info.DBschema,
		})
	})
}