#include "carbonyl/src/browser/render_service_impl.h"

#include <iostream>

#include "carbonyl/src/browser/renderer.h"

namespace carbonyl {

CarbonylRenderServiceImpl::CarbonylRenderServiceImpl(
    mojo::PendingReceiver<mojom::CarbonylRenderService> receiver):
    receiver_(this, std::move(receiver))
{}

CarbonylRenderServiceImpl::~CarbonylRenderServiceImpl() = default;

void CarbonylRenderServiceImpl::DrawText(std::vector<mojom::TextDataPtr> data) {
    std::vector<Text> mapped;

    for (auto& text: data) {
        mapped.emplace_back(text->contents, text->bounds, text->color);
    }

    Renderer::GetCurrent()->DrawText(mapped);
}

}
