package handler

import (
	"net/http"

	"amazonpilot/internal/optimization/internal/logic"
	"amazonpilot/internal/optimization/internal/svc"
	"amazonpilot/internal/optimization/internal/types"
	"github.com/zeromicro/go-zero/rest/httpx"
)

func OptimizationHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.Request
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}

		l := logic.NewOptimizationLogic(r.Context(), svcCtx)
		resp, err := l.Optimization(&req)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
