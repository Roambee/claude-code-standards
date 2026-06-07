import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
    DataTable,
    Button,
    Badge,
    Input,
    Breadcrumbs,
    Select,
    SelectTrigger,
    SelectValue,
    SelectContent,
    SelectItem,
} from "@decklar/ui-library";
import type { TableActionMenuItem, BreadcrumbItem } from "@decklar/ui-library";
import type { ColumnDef, Row } from "@tanstack/react-table";
import { Search, Plus, Download } from "lucide-react";

// TODO: replace with your actual row type
type RowItem = {
    id: string;
    name: string;
    status: "active" | "inactive" | "pending";
    date: string;
};

const columns: ColumnDef<RowItem>[] = [
    { accessorKey: "name", header: "Name" },
    {
        accessorKey: "status",
        header: "Status",
        cell: ({ getValue }) => {
            const value = getValue() as string;
            const variant = value === "active" ? "success" : value === "inactive" ? "error" : "warning";
            return <Badge variant={variant}>{value}</Badge>;
        },
    },
    { accessorKey: "date", header: "Date" },
];

// TODO: replace with real data / API call
const MOCK_DATA: RowItem[] = [
    { id: "1", name: "Item One", status: "active", date: "2026-03-01" },
    { id: "2", name: "Item Two", status: "pending", date: "2026-03-10" },
];

export default function DataTablePageName() {
    const navigate = useNavigate();
    const [search, setSearch] = useState("");
    const [statusFilter, setStatusFilter] = useState("all");

    const breadcrumbs: BreadcrumbItem[] = [
        { label: "Home", onClick: () => navigate("/") },
        { label: "Table Title" },
    ];

    const filtered = MOCK_DATA.filter((row) => {
        const q = search.toLowerCase();
        const matchSearch = !q || row.name.toLowerCase().includes(q);
        const matchStatus = statusFilter === "all" || row.status === statusFilter;
        return matchSearch && matchStatus;
    });

    function getRowActions(row: Row<RowItem>): TableActionMenuItem[] {
        return [
            { id: "view", label: "View", onClick: () => console.log("view", row.original) },
            {
                id: "delete",
                label: "Delete",
                variant: "destructive",
                onClick: () => console.log("delete", row.original.id),
            },
        ];
    }

    return (
        <div className="flex flex-col gap-4 p-6">
            <Breadcrumbs items={breadcrumbs} />

            {/* Page header: title + primary actions (always visible in narrow layouts) */}
            <div className="flex items-center justify-between gap-4">
                <h1 className="text-2xl font-semibold text-text-primary shrink-0">Table Title</h1>
                <div className="flex items-center gap-2 shrink-0">
                    <Button variant="outline" onClick={() => console.log("export")}>
                        <Download size={16} /> Export CSV
                    </Button>
                    <Button variant="primary">
                        <Plus size={16} /> Add Item
                    </Button>
                </div>
            </div>

            {/* Filter row: wrap on small widths; SelectTrigger needs explicit width */}
            <div className="flex flex-wrap items-center gap-3">
                <div className="relative min-w-[180px] max-w-xs flex-1">
                    <Search
                        className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary pointer-events-none"
                        size={16}
                    />
                    <Input
                        className="pl-9"
                        placeholder="Search…"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="w-40">
                        <SelectValue placeholder="All status" />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="all">All status</SelectItem>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="inactive">Inactive</SelectItem>
                        <SelectItem value="pending">Pending</SelectItem>
                    </SelectContent>
                </Select>
            </div>

            <DataTable
                columns={columns}
                data={filtered}
                getRowId={(row) => row.id}
                enableRowSelection
                enableColumnResizing
                showPageNumbers
                initialPageSize={20}
                getRowActions={getRowActions}
            />
        </div>
    );
}
