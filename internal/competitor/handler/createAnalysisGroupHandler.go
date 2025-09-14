package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/competitor/logic"
	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/utils"
)

func createAnalysisGroupHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.CreateAnalysisRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewCreateAnalysisGroupLogic(r.Context(), svcCtx)
		resp, err := l.CreateAnalysisGroup(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
