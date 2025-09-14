package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/product/logic"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/utils"
)

func getTrackedProductsHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.GetTrackedRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewGetTrackedProductsLogic(r.Context(), svcCtx)
		resp, err := l.GetTrackedProducts(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
