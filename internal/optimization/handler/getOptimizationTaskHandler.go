package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/optimization/logic"
	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"
	"amazonpilot/internal/pkg/utils"
)

func getOptimizationTaskHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GetOptimizationRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewGetOptimizationTaskLogic(r.Context(), svcCtx)
		resp, err := l.GetOptimizationTask(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
