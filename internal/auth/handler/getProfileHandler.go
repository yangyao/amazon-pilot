package handler

import (
	"net/http"

	"amazonpilot/internal/auth/logic"
	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/rest/httpx"
)

func getProfileHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		l := logic.NewGetProfileLogic(r.Context(), svcCtx)
		resp, err := l.GetProfile()
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
