package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/product/logic"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/utils"
)

func getProductHistoryHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GetHistoryRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewGetProductHistoryLogic(r.Context(), svcCtx)
		resp, err := l.GetProductHistory(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
