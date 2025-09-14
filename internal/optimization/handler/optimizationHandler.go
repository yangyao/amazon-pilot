package handler

import (
	"net/http"

	"amazonpilot/internal/optimization/logic"
	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"
	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/pkg/utils"
)

func OptimizationHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GetOptimizationRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewOptimizationLogic(r.Context(), svcCtx)
		resp, err := l.Optimization(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
