package handler

import (
	"net/http"

	"amazonpilot/internal/auth/logic"
	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/rest/httpx"
)

func healthHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		l := logic.NewHealthLogic(r.Context(), svcCtx)
		resp, err := l.Health()
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
