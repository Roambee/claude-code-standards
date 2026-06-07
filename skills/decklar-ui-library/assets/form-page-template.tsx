import React from "react";
import { useNavigate } from "react-router-dom";
import { z } from "zod";
import { Form, FormInput, FormSelect, FormCheckbox, Button, Breadcrumbs } from "@decklar/ui-library";
import { SelectItem } from "@decklar/ui-library";
import type { BreadcrumbItem } from "@decklar/ui-library";

const schema = z.object({
    name: z.string().min(2, "Name must be at least 2 characters"),
    email: z.string().email("Invalid email address"),
    role: z.enum(["admin", "editor", "viewer"]),
    acceptTerms: z.boolean().refine((v) => v === true, "You must accept the terms"),
});

type FormValues = z.infer<typeof schema>;

export default function FormPageName() {
    const navigate = useNavigate();

    const breadcrumbs: BreadcrumbItem[] = [
        { label: "Home", onClick: () => navigate("/") },
        { label: "Section", onClick: () => navigate("/section") },
        { label: "Form Title" }
    ];

    async function handleSubmit(values: FormValues) {
        // TODO: call API
        console.log(values);
    }

    return (
        <div className="flex flex-col gap-6 p-6 max-w-xl">
            <Breadcrumbs items={breadcrumbs} />
            <h1 className="text-2xl font-semibold text-text-primary">Form Title</h1>

            <Form schema={schema} defaultValues={{ name: "", email: "", acceptTerms: false }} onSubmit={handleSubmit}>
                <div className="flex flex-col gap-4">
                    <FormInput name="name" label="Name" placeholder="Jane Doe" />
                    <FormInput name="email" label="Email" type="email" placeholder="jane@example.com" />

                    <FormSelect name="role" label="Role" placeholder="Select a role">
                        <SelectItem value="admin">Admin</SelectItem>
                        <SelectItem value="editor">Editor</SelectItem>
                        <SelectItem value="viewer">Viewer</SelectItem>
                    </FormSelect>

                    <FormCheckbox name="acceptTerms" label="I accept the terms and conditions" />

                    <div className="flex gap-3 pt-2">
                        <Button type="submit" variant="primary">
                            Submit
                        </Button>
                        <Button type="button" variant="secondary">
                            Cancel
                        </Button>
                    </div>
                </div>
            </Form>
        </div>
    );
}
