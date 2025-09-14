package handler

import (
	"net/http"

	"amazonpilot/internal/product/logic"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/pkg/utils"
)

func getAnomalyEventsHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GetAnomalyEventsRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewGetAnomalyEventsLogic(r.Context(), svcCtx)
		resp, err := l.GetAnomalyEvents(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}