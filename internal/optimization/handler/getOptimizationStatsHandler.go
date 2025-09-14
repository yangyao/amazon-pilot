package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/optimization/logic"
	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/pkg/utils"
)

func getOptimizationStatsHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		l := logic.NewGetOptimizationStatsLogic(r.Context(), svcCtx)
		resp, err := l.GetOptimizationStats()
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
