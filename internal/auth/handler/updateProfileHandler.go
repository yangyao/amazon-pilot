package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/auth/logic"
	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"
	"amazonpilot/internal/pkg/utils"
)

func updateProfileHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.ProfileUpdateRequest
		if err := httpx.Parse(r, &req); err != nil {
			utils.HandleError(w, err)
			return
		}

		l := logic.NewUpdateProfileLogic(r.Context(), svcCtx)
		resp, err := l.UpdateProfile(&req)
		if err != nil {
			utils.HandleError(w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
