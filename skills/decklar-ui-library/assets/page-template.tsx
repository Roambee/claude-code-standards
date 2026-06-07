import React from "react";
import { useNavigate } from "react-router-dom";
import { Button, Breadcrumbs } from "@decklar/ui-library";
import type { BreadcrumbItem } from "@decklar/ui-library";

export default function PageName() {
    const navigate = useNavigate();

    const breadcrumbs: BreadcrumbItem[] = [
        { label: "Home", onClick: () => navigate("/") },
        { label: "Page Title" }
    ];

    return (
        <div className="flex flex-col gap-6 p-6">
            <Breadcrumbs items={breadcrumbs} />
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-semibold text-text-primary">Page Title</h1>
                <Button variant="primary">Action</Button>
            </div>

            {/* Page content */}
        </div>
    );
}
