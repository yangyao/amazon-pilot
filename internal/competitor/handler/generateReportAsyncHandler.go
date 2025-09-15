package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/competitor/logic"
	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/utils"
)

func generateReportAsyncHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GenerateReportAsyncRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewGenerateReportAsyncLogic(r.Context(), svcCtx)
		resp, err := l.GenerateReportAsync(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
